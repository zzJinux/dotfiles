#!/usr/bin/env bash
# shellcheck disable=all

# Functions required by the openstack completion script
# Source: https://github.com/scop/bash-completion/blob/v2.11.0/bash_completion

if [[ -n $BASH ]]; then
    return
fi

_get_comp_words_by_ref()
{
    local exclude flag i OPTIND=1
    local cur cword words=()
    local upargs=() upvars=() vcur vcword vprev vwords

    while getopts "c:i:n:p:w:" flag "$@"; do
        case $flag in
            c) vcur=$OPTARG ;;
            i) vcword=$OPTARG ;;
            n) exclude=$OPTARG ;;
            p) vprev=$OPTARG ;;
            w) vwords=$OPTARG ;;
            *)
                echo "bash_completion: $FUNCNAME: usage error" >&2
                return 1
                ;;
        esac
    done
    while [[ $# -ge $OPTIND ]]; do
        case ${!OPTIND} in
            cur) vcur=cur ;;
            prev) vprev=prev ;;
            cword) vcword=cword ;;
            words) vwords=words ;;
            *)
                echo "bash_completion: $FUNCNAME: \`${!OPTIND}':" \
                    "unknown argument" >&2
                return 1
                ;;
        esac
        ((OPTIND += 1))
    done

    __get_cword_at_cursor_by_ref "${exclude-}" words cword cur

    [[ -v vcur ]] && {
        upvars+=("$vcur")
        upargs+=(-v $vcur "$cur")
    }
    [[ -v vcword ]] && {
        upvars+=("$vcword")
        upargs+=(-v $vcword "$cword")
    }
    [[ -v vprev && $cword -ge 1 ]] && {
        upvars+=("$vprev")
        upargs+=(-v $vprev "${words[cword - 1]}")
    }
    [[ -v vwords ]] && {
        upvars+=("$vwords")
        upargs+=(-a${#words[@]} $vwords ${words+"${words[@]}"})
    }

    ((${#upvars[@]})) && local "${upvars[@]}" && _upvars "${upargs[@]}"
}

__get_cword_at_cursor_by_ref()
{
    local cword words=()
    __reassemble_comp_words_by_ref "$1" words cword

    local i cur="" index=$COMP_POINT lead=${COMP_LINE:0:COMP_POINT}
    # Cursor not at position 0 and not leaded by just space(s)?
    if [[ $index -gt 0 && ($lead && ${lead//[[:space:]]/}) ]]; then
        cur=$COMP_LINE
        for ((i = 0; i <= cword; ++i)); do
            # Current word fits in $cur, and $cur doesn't match cword?
            while [[ ${#cur} -ge ${#words[i]} && \
                ${cur:0:${#words[i]}} != "${words[i]-}" ]]; do
                # Strip first character
                cur="${cur:1}"
                # Decrease cursor position, staying >= 0
                ((index > 0)) && ((index--))
            done

            # Does found word match cword?
            if ((i < cword)); then
                # No, cword lies further;
                local old_size=${#cur}
                cur="${cur#"${words[i]}"}"
                local new_size=${#cur}
                ((index -= old_size - new_size))
            fi
        done
        # Clear $cur if just space(s)
        [[ $cur && ! ${cur//[[:space:]]/} ]] && cur=
        # Zero $index if negative
        ((index < 0)) && index=0
    fi

    local "$2" "$3" "$4" && _upvars -a${#words[@]} $2 ${words+"${words[@]}"} \
        -v $3 "$cword" -v $4 "${cur:0:index}"
}

__reassemble_comp_words_by_ref()
{
    local exclude i j line ref
    # Exclude word separator characters?
    if [[ $1 ]]; then
        # Yes, exclude word separator characters;
        # Exclude only those characters, which were really included
        exclude="[${1//[^$COMP_WORDBREAKS]/}]"
    fi

    # Default to cword unchanged
    printf -v "$3" %s "$COMP_CWORD"
    # Are characters excluded which were former included?
    if [[ -v exclude ]]; then
        # Yes, list of word completion separators has shrunk;
        line=$COMP_LINE
        # Re-assemble words to complete
        for ((i = 0, j = 0; i < ${#COMP_WORDS[@]}; i++, j++)); do
            # Is current word not word 0 (the command itself) and is word not
            # empty and is word made up of just word separator characters to
            # be excluded and is current word not preceded by whitespace in
            # original line?
            while [[ $i -gt 0 && ${COMP_WORDS[i]} == +($exclude) ]]; do
                # Is word separator not preceded by whitespace in original line
                # and are we not going to append to word 0 (the command
                # itself), then append to current word.
                [[ $line != [[:blank:]]* ]] && ((j >= 2)) && ((j--))
                # Append word separator to current or new word
                ref="$2[$j]"
                printf -v "$ref" %s "${!ref-}${COMP_WORDS[i]}"
                # Indicate new cword
                ((i == COMP_CWORD)) && printf -v "$3" %s "$j"
                # Remove optional whitespace + word separator from line copy
                line=${line#*"${COMP_WORDS[i]}"}
                # Start new word if word separator in original line is
                # followed by whitespace.
                [[ $line == [[:blank:]]* ]] && ((j++))
                # Indicate next word if available, else end *both* while and
                # for loop
                ((i < ${#COMP_WORDS[@]} - 1)) && ((i++)) || break 2
            done
            # Append word to current word
            ref="$2[$j]"
            printf -v "$ref" %s "${!ref-}${COMP_WORDS[i]}"
            # Remove optional whitespace + word from line copy
            line=${line#*"${COMP_WORDS[i]}"}
            # Indicate new cword
            ((i == COMP_CWORD)) && printf -v "$3" %s "$j"
        done
        ((i == COMP_CWORD)) && printf -v "$3" %s "$j"
    else
        # No, list of word completions separators hasn't changed;
        for i in "${!COMP_WORDS[@]}"; do
            printf -v "$2[i]" %s "${COMP_WORDS[i]}"
        done
    fi
}