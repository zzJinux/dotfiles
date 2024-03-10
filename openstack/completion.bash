_fzf_complete_osc() {
  local cfg
  cfg=$(_openstack_locate_config)
  if [ -z "$cfg" ]; then
    return 1
  fi

  if _fzf_complete --multi --reverse --prompt="cloud> " -- "$@"; then
    return
  elif [ "${#COMP_WORDS[@]}" == "2" ]; then
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local IFS=''
    read -rd '' wordlist
    IFS=$'\n'
    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "$wordlist" -- "$cur") )
  fi < <(yq '.clouds|keys|.[]' "$cfg")
}
complete -F _fzf_complete_osc osc osce