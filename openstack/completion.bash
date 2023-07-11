_fzf_complete_osc() {
  if _fzf_complete --multi --reverse --prompt="cloud> " -- "$@"; then
    return
  elif [ "${#COMP_WORDS[@]}" == "2" ]; then
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local IFS=''
    read -rd '' wordlist
    IFS=$'\n'
    COMPREPLY=( $(compgen -W "$wordlist" -- "$cur") )
  fi < <(yq '.clouds|keys|.[]' ~/.config/openstack/clouds.yaml)
}
complete -F _fzf_complete_osc osc