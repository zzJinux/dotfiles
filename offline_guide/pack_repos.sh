#!/usr/bin/env bash

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"; do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

shopt -s extglob

squash_repo_local() {
  local src_dir=$1
  local repo_url=$(execute git -C "$src_dir" remote get-url origin)
  local revision=$(execute git -C "$src_dir" rev-parse HEAD)
  local default_branch=$(execute git -C "$src_dir" symbolic-ref --short -q HEAD)
  local repo_name=$(sed 's|https\{0,1\}://\([^/@]*@\)\{0,1\}||g' <<<"${repo_url}")

  execute mkdir -p "${repo_name}"
  execute pushd "${repo_name}" >/dev/null
    execute git clone -q --depth=1 "file://$src_dir" .
    execute rm -rf .git
    execute git -c "init.defaultBranch=${default_branch}" init -q
    execute git config --bool core.autocrlf false
    execute git add .
    execute git commit -q -m "${repo_name} ${revision}"
  execute popd >/dev/null
}

squash_repo() {
  local repo_name=$1
  local repo_url=https://$repo_name

  execute mkdir -p "${repo_name}"
  execute pushd "${repo_name}" >/dev/null
    execute git clone -q --depth=1 "$repo_url" .
    local revision=$(execute git rev-parse HEAD)
    local default_branch=$(execute git symbolic-ref --short -q HEAD)
    execute rm -rf .git
    execute git -c "init.defaultBranch=${default_branch}" init -q
    execute git config --bool core.autocrlf false
    execute git add .
    execute git commit -q -m "${repo_name} ${revision}"
  execute popd >/dev/null
}

tmpdir=$(execute mktemp -d)
echo "Output goes $tmpdir"
execute cd "$tmpdir"
HOMEBREW_PREFIX=$(brew --prefix)

squash_repo_local "$HOMEBREW_PREFIX"
squash_repo_local "$HOMEBREW_PREFIX/Library/Taps/homebrew/homebrew-core"
squash_repo github.com/Homebrew/install

for src_dir in ~/.vim/plugged/*; do
  squash_repo_local "$src_dir"
done

for src_dir in ~/.config/tmux/plugins/*; do
  squash_repo_local "$src_dir"
done

tar -czf repos.tar.gz -C "$tmpdir" .

# git archive --remote=file:///absolute/path/github.com/Homebrew/install.git HEAD hello | tar -xO