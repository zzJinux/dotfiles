_fzf_complete_kx() {
  if _fzf_complete --multi --reverse --prompt="context> " -- "$@"; then
    return
  elif [ "${#COMP_WORDS[@]}" == "2" ]; then
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local IFS=''
    read -rd '' wordlist
    IFS=$'\n'
    COMPREPLY=( $(compgen -W "$wordlist" -- "$cur") )
  fi < <(find -L ~/.kube/clusters -mindepth 1 -maxdepth 1 -type d -exec basename '{}' \;)
}
complete -F _fzf_complete_kx kx

_fzf_complete_kpf() {
  if _fzf_complete --multi --reverse --prompt="target> " -- "$@"; then
    return
  elif [ "${#COMP_WORDS[@]}" == "2" ]; then
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local IFS=''
    read -rd '' wordlist
    IFS=$'\n'
    COMPREPLY=( $(compgen -W "$wordlist" -- "$cur") )
  fi < <(builtin cd ~/.kube/portforwards && find -L . -type f | cut -c3-)
}
complete -F _fzf_complete_kpf kpf

_fzf_complete_kjmp() {
  if _fzf_complete --multi --reverse --prompt="target> " -- "$@"; then
    return
  elif [ "${#COMP_WORDS[@]}" == "2" ]; then
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local IFS=''
    read -rd '' wordlist
    IFS=$'\n'
    COMPREPLY=( $(compgen -W "$wordlist" -- "$cur") )
  fi < <(builtin cd ~/.kube/jumpremotes && find -L . -type f | cut -c3-)
}
complete -F _fzf_complete_kjmp kjmp