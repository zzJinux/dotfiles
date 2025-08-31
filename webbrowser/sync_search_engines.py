#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "pydantic",
#     "json5",
# ]
# ///

import argparse
import shutil
import sqlite3
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

import json5
import pydantic


class SearchEngineItem(pydantic.BaseModel):
    short_name: str
    keyword: str
    url: str = ""
    favicon_url: str = ""
    prepopulate_id: int = 0


class SearchEngineConfig(pydantic.BaseModel):
    items: list[SearchEngineItem]


def to_webkittime(dt: datetime) -> int:
    """Convert datetime to webkit time format (microseconds since Jan 1, 1601 00:00 UTC)"""
    # Webkit epoch: January 1, 1601 00:00:00 UTC
    webkit_epoch = datetime(1601, 1, 1, tzinfo=timezone.utc)
    delta = dt - webkit_epoch
    return int(delta.total_seconds() * 1_000_000)


def backup_database(db_path: Path) -> Path:
    """Create a backup of the database file"""
    backup_path = db_path.with_suffix(f".backup.{int(datetime.now().timestamp())}")
    shutil.copy2(db_path, backup_path)
    return backup_path


def load_config(config_path: Path) -> SearchEngineConfig:
    """Load and validate the JSON5 config file"""
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            data = json5.load(f)
            config = SearchEngineConfig.model_validate(data)
        return config
    except Exception as e:
        print(f"Error loading config file: {e}", file=sys.stderr)
        sys.exit(1)


def sync_search_engines(
    db_path: Path, config: SearchEngineConfig, dry_run: bool = False, confirm: bool = False
) -> None:
    if not dry_run and not confirm:
        print("Error: Use --confirm to ensure the database is not in use and confirm modifications.", file=sys.stderr)
        sys.exit(1)
    TABLE_NAME = "keywords"
    conn = sqlite3.connect(db_path)
    conn.autocommit = False
    try:
        cursor = conn.cursor()

        current_wktime = to_webkittime(datetime.now(timezone.utc))

        # Group items by short_name
        grouped_items = defaultdict(list)
        for item in config.items:
            grouped_items[item.short_name].append(item)

        updated_count = 0
        unchanged_count = 0
        inserted_count = 0
        deleted_count = 0
        skipped_count = 0  # For inserts that are skipped due to missing URL

        for short_name, items in grouped_items.items():
            # 1. If there are more than one prepopulate_id >= 10000, prepopulate_id < 10000 shouldn't exist.
            # 2. Otherwise, prepopulate_id < 10000 should exist at most once.
            cursor.execute(f"SELECT id, prepopulate_id FROM {TABLE_NAME} WHERE short_name = ?", (short_name,))
            rows = [{'id': e[0], 'prepopulate_id': e[1]} for e in cursor.fetchall()]
            if len([row for row in rows if row['prepopulate_id'] >= 10000]) > 1:
                if any(row['prepopulate_id'] < 10000 for row in rows):
                    raise Exception(f"Data integrity error for {short_name}: multiple prepopulate_id >= 10000 and some < 10000")
            else:
                if len([row for row in rows if row['prepopulate_id'] < 10000]) > 1:
                    raise Exception(f"Data integrity error for {short_name}: multiple prepopulate_id < 10000")

            # Get keywords from config for this short_name
            config_keywords = {item.keyword for item in items}
            assert len(config_keywords) > 0
            config_items_by_keyword = {item.keyword: item for item in items}

            # Get keywords from database for this short_name
            cursor.execute(f"SELECT keyword FROM {TABLE_NAME} WHERE short_name = ?", (short_name,))
            db_keywords = {row[0] for row in cursor.fetchall()}

            # Keywords to insert, update, delete
            to_insert = list(config_keywords - db_keywords)
            to_update = list(config_keywords & db_keywords)
            to_delete = list(db_keywords - config_keywords)

            # 1. Update existing records (present in both config and DB)
            for keyword in to_update:
                item = config_items_by_keyword[keyword]
                # Fetch current prepopulate_id from DB
                cursor.execute(
                    f"SELECT prepopulate_id FROM {TABLE_NAME} WHERE short_name = ? AND keyword = ?",
                    (short_name, keyword),
                )
                row = cursor.fetchone()
                db_prepopulate_id = row[0] if row else None
                if db_prepopulate_id >= 10000:
                    # Build update statement dynamically to skip favicon_url if empty
                    update_fields = ["url = ?", "prepopulate_id = ?", "last_modified = ?"]
                    update_values = [item.url, item.prepopulate_id, current_wktime]
                    if item.favicon_url:
                        update_fields.append("favicon_url = ?")
                        update_values.append(item.favicon_url)
                    update_fields_str = ", ".join(update_fields)
                    if not dry_run:
                        cursor.execute(
                            f"UPDATE {TABLE_NAME} SET {update_fields_str} WHERE short_name = ? AND keyword = ?",
                            (*update_values, short_name, keyword),
                        )
                    updated_count += 1
                    print(
                        f"UPDATE: {short_name} (keyword: {keyword}, prepopulate_id: {item.prepopulate_id})"
                    )

            # 2. Reuse records: update deleted ones to become inserted ones
            reuse_count = min(len(to_insert), len(to_delete))
            for i in range(reuse_count):
                old_keyword = to_delete[i]
                new_keyword = to_insert[i]
                item = config_items_by_keyword[new_keyword]
                if not item.url:
                    skipped_count += 1
                    print(f"SKIP: {short_name} (keyword: {new_keyword}, no URL provided)")
                    continue
                # Fetch current prepopulate_id from DB for the old_keyword
                cursor.execute(
                    f"SELECT prepopulate_id FROM {TABLE_NAME} WHERE short_name = ? AND keyword = ?",
                    (short_name, old_keyword),
                )
                row = cursor.fetchone()
                db_prepopulate_id = row[0] if row else None
                if db_prepopulate_id is not None and db_prepopulate_id < 10000:
                    # Only update keyword and last_modified
                    update_fields = ["keyword = ?", "last_modified = ?"]
                    update_values = [new_keyword, current_wktime]
                    update_fields_str = ", ".join(update_fields)
                    if not dry_run:
                        cursor.execute(
                            f"UPDATE {TABLE_NAME} SET {update_fields_str} WHERE short_name = ? AND keyword = ?",
                            (*update_values, short_name, old_keyword),
                        )
                    updated_count += 1
                    print(
                        f"RENAME: {short_name} (from keyword: {old_keyword} to {new_keyword}, prepopulate_id: {db_prepopulate_id})"
                    )
                else:
                    # Build update statement dynamically to skip favicon_url if empty
                    update_fields = ["keyword = ?", "url = ?", "prepopulate_id = ?", "last_modified = ?"]
                    update_values = [new_keyword, item.url, item.prepopulate_id, current_wktime]
                    if item.favicon_url:
                        update_fields.append("favicon_url = ?")
                        update_values.append(item.favicon_url)
                    update_fields_str = ", ".join(update_fields)
                    if not dry_run:
                        cursor.execute(
                            f"UPDATE {TABLE_NAME} SET {update_fields_str} WHERE short_name = ? AND keyword = ?",
                            (*update_values, short_name, old_keyword),
                        )
                    updated_count += 1
                    print(
                        f"RENAME+UPDATE: {short_name} (from keyword: {old_keyword} to {new_keyword}, prepopulate_id: {item.prepopulate_id})"
                    )

            # 3. Insert any remaining new keywords
            for keyword in to_insert[reuse_count:]:
                item = config_items_by_keyword[keyword]
                if not item.url:
                    skipped_count += 1
                    print(f"SKIP: {short_name} (keyword: {keyword}, no URL provided)")
                    continue
                if not dry_run:
                    cursor.execute(
                        f"""
                        INSERT INTO {TABLE_NAME} (
                            short_name, keyword, url, favicon_url, safe_for_autoreplace,
                            originating_url, date_created, input_encodings, suggest_url,
                            prepopulate_id, last_modified, alternate_urls, image_url,
                            search_url_post_params, suggest_url_post_params,
                            image_url_post_params, new_tab_url, is_active
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            short_name,
                            item.keyword,
                            item.url,
                            item.favicon_url,
                            0,
                            "",
                            current_wktime,
                            "",
                            "",
                            item.prepopulate_id,
                            current_wktime,
                            "[]",
                            "",
                            "",
                            "",
                            "",
                            "",
                            1,
                        ),
                    )
                inserted_count += 1
                print(f"INSERT: {short_name} (keyword: {keyword})")

            # 4. Delete any remaining old keywords
            for keyword in to_delete[reuse_count:]:
                if not dry_run:
                    cursor.execute(
                        f"DELETE FROM {TABLE_NAME} WHERE short_name = ? AND keyword = ?",
                        (short_name, keyword),
                    )
                deleted_count += 1
                print(f"DELETE: {short_name} (keyword: {keyword})")

        if not dry_run:
            conn.commit()
            print("\nSync completed:")
            print(f"  Updated: {updated_count}")
            print(f"  Inserted: {inserted_count}")
            print(f"  Deleted: {deleted_count}")
            print(f"  Skipped: {skipped_count}")
        else:
            print("\nDry run completed:")
            print(f"  Would update: {updated_count}")
            print(f"  Would insert: {inserted_count}")
            print(f"  Would delete: {deleted_count}")
            print(f"  Would skip: {skipped_count}")

    except sqlite3.Error as e:
        print(f"Database error: {e}", file=sys.stderr)
        conn.rollback()
        raise
    finally:
        conn.close()


def main():
    parser = argparse.ArgumentParser(description="Sync search engine configurations with Chrome's Web Data database")
    parser.add_argument("web_data_path", type=Path, help="Path to Chrome's 'Web Data' database file")
    parser.add_argument("config_file", type=Path, help="Path to JSON5 config file")
    parser.add_argument("--dry-run", action="store_true", help="Preview changes without making them")
    parser.add_argument(
        "--confirm",
        action="store_true",
        help="Confirm that the database is not in use and the browser sync is disabled before proceeding with modifications",
    )
    parser.add_argument("--no-backup", action="store_true", help="Skip creating database backup")

    args = parser.parse_args()

    # Validate inputs
    if not args.web_data_path.exists():
        print(f"Error: Web Data file not found: {args.web_data_path}", file=sys.stderr)
        sys.exit(1)

    if not args.config_file.exists():
        print(f"Error: Config file not found: {args.config_file}", file=sys.stderr)
        sys.exit(1)

    # Load config
    print(f"Loading config from: {args.config_file}")
    config = load_config(args.config_file)
    print(f"Found {len(config.items)} search engine entries")

    # Create backup if not dry run
    if not args.dry_run and not args.no_backup:
        print(f"Creating backup of: {args.web_data_path}")
        backup_path = backup_database(args.web_data_path)
        print(f"Backup created: {backup_path}")

    # Sync search engines
    print(f"\nSyncing with database: {args.web_data_path}")
    if args.dry_run:
        print("DRY RUN MODE - No changes will be made")

    sync_search_engines(args.web_data_path, config, args.dry_run, args.confirm)
    if not args.dry_run:
        print("Sync complete. Don't forget to re-enable browser sync.")


if __name__ == "__main__":
    main()
