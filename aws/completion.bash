_fzf_complete_awsp() {
  if _fzf_complete --multi --reverse --prompt="profile> " -- "$@"; then
    return
  elif [ "${#COMP_WORDS[@]}" == "2" ]; then
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local IFS=''
    read -rd '' wordlist
    IFS=$'\n'
    COMPREPLY=( $(compgen -W "$wordlist" -- "$cur") )
  fi < <(COMP_LINE='aws --profile ' COMP_POINT=14 aws_completer)
}
complete -F _fzf_complete_awsp awsp