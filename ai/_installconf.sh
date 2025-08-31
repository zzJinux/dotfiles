#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai ai:installconf
execute mkdir -p "$HOME/.gemini" "$HOME/.claude" "$HOME/.codex"
execute symlink_safe "$SCRIPT_DIR/instructions.md" "$HOME/.gemini/GEMINI.md"
execute symlink_safe "$SCRIPT_DIR/instructions.md" "$HOME/.claude/CLAUDE.md"
execute symlink_safe "$SCRIPT_DIR/instructions.md" "$HOME/.codex/AGENTS.md"