if [ -t 1 ]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_yellow="$(tty_escape 33)"
tty_blue="$(tty_escape 34)"
tty_bblue="$(tty_escape 94)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

loginfo() { echo "${tty_bblue}$*${tty_reset}" >&2; }
logerror() { echo "${tty_yellow}$*${tty_reset}" >&2; }

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

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

ohai() {
  printf "${tty_blue}dotfiles>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

have_sudo_access() {
  if [[ ! -x "/usr/bin/sudo" ]]; then
    return 1
  fi

  local -a SUDO=("/usr/bin/sudo")
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    SUDO+=("-A")
  elif [[ -n "${NONINTERACTIVE-}" ]]; then
    SUDO+=("-n")
  fi

  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
    if [[ -n "${NONINTERACTIVE-}" ]]; then
      "${SUDO[@]}" -l mkdir &>/dev/null
    else
      "${SUDO[@]}" -v && "${SUDO[@]}" -l mkdir &>/dev/null
    fi
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ "${HAVE_SUDO_ACCESS}" -ne 0 ]]; then
    abort "Need sudo access on macOS (e.g. the user ${USER} needs to be an Administrator)!"
  fi
}

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

execute_sudo() {
  local -a args=("$@")
  if [[ "${EUID:-${UID}}" != "0" ]] && have_sudo_access; then
    if [[ -n "${SUDO_ASKPASS-}" ]]; then
      args=("-A" "${args[@]}")
    fi
    ohai "/usr/bin/sudo" "${args[@]}"
    execute "/usr/bin/sudo" "${args[@]}"
  else
    ohai "${args[@]}"
    execute "${args[@]}"
  fi
}

quote() {
  builtin printf %q "$1"
}

script_dir() {
  (cd -- "$(dirname -- "${BASH_SOURCE[1]}")" &>/dev/null && pwd)
}

_script_dir() {
  (cd -- "$(dirname -- "${BASH_SOURCE[1]}")" &>/dev/null && pwd)
}

symlink_safe() {
  local source="$1"
  local target="$2"
  if ! [ -e "$source" ]; then
    logerror "symlink_safe: source does not exist: $source"
    return 1
  fi
  if [ -e "$target" ]; then
    if [ -L "$target" ]; then
      old_src=$(readlink "$target")
      if [ "$old_src" = "$source" ]; then
        loginfo "symlink_safe: skip: $target already points to $source"
        return 0
      fi
      loginfo "symlink_safe: $target points to $old_src"
      loginfo "symlink_safe: removing existing symlink: $target"
      rm "$target"
    elif [ -f "$target" ]; then
      loginfo "symlink_safe: backing up existing file: $target"
      mv "$target" "$target.bak"
    else
      logerror "symlink_safe: $target is unknown type, remove it manually"
      return 1
    fi
  fi
  ln -sv "$source" "$target"
}

write_safe() {
  local dest="$1"
  if [ -e "$dest" ]; then
    if [ -L "$dest" ]; then
      old_src=$(readlink "$dest")
      loginfo "write_safe: $dest points to $old_src"
      loginfo "write_safe: removing existing symlink: $dest"
      rm "$dest"
    elif [ -f "$dest" ]; then
      loginfo "write_safe: backing up existing file: $dest"
      mv "$dest" "$dest.bak"
    else
      logerror "write_safe: $dest is unknown type, remove it manually"
      return 1
    fi
  fi
  echo writing to "$dest"
  cat >"$dest"
}

dir_bin() {
  echo "$1/bin"
}
dir_sbin() {
  echo "$1/bin"
}
dir_man1() {
  echo "$1/share/man/man1"
}
dir_man5() {
  echo "$1/share/man/man5"
}

LOCAL_BIN=$(dir_bin ~/.local)
LOCAL_SBIN=$(dir_sbin ~/.local)
LOCAL_MAN1=$(dir_man1 ~/.local)
LOCAL_MAN5=$(dir_man5 ~/.local)
mkdir -p "$LOCAL_BIN" "$LOCAL_SBIN" "$LOCAL_MAN1" "$LOCAL_MAN5"

link_bin() {
  local name=$1
  local src_prefix=${2:-$HOMEBREW_PREFIX}
  local src_name=${3:-$name}

  symlink_safe "$src_prefix/bin/$src_name" "$LOCAL_BIN/$name"
}

unlink_bin() {
  local name=$1
  rm -f "$LOCAL_BIN/$name"
}

link_sbin() {
  local name=$1
  local src_prefix=${2:-$HOMEBREW_PREFIX}
  local src_name=${3:-$name}

  symlink_safe "$src_prefix/sbin/$src_name" "$LOCAL_SBIN/$name"
}

unlink_sbin() {
  local name=$1
  rm -f "$LOCAL_SBIN/$name"
}

link_man1() {
  local name=$1
  local src_prefix=${2:-$HOMEBREW_PREFIX}
  local src_name=${3:-$name}

  symlink_safe "$src_prefix/share/man/man1/$src_name.1" "$LOCAL_MAN1/$name.1"
}

unlink_man1() {
  local name=$1
  rm -f "$LOCAL_MAN1/$name.1"
}

link_man5() {
  local name=$1
  local src_prefix=${2:-$HOMEBREW_PREFIX}
  local src_name=${3:-$name}

  symlink_safe "$src_prefix/share/man/man5/$src_name.5" "$LOCAL_MAN5/$name.5"
}

unlink_man5() {
  local name=$1
  rm -f "$LOCAL_MAN5/$name.5"
}
