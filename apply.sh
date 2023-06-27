#!/bin/sh

src=.staging
dest=$HOME

# Copy files recursively from source to destination
find "$src" -type f \! -iname .DS_Store -exec sh -c '
  src_file="$1"
  src_dir=$2
  dest_dir=$3
  rel_path="${src_file#"${src_dir}/"}"
  dest_file="$dest_dir/$rel_path"
  mkdir -p "$(dirname "$dest_file")"
  cp "$src_file" "$dest_file"
' sh {} "$src" "$dest" \;
