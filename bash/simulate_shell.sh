#!/bin/bash

whitelist=(__CFBundleIdentifier USER TMPDIR TERM TERM_PROGRAM TERM_PROGRAM_VERSION LC_CTYPE)
filtered_vars=()

while IFS=$'\n' read -r var; do
  if [[ " ${whitelist[*]} " == *" ${var%%=*} "* ]]; then
    filtered_vars+=("$var")
  fi
done < <(env)

# Execute command with whitelist of environment variables
exec -l env -i "${filtered_vars[@]}" HOME="$PWD" bash -l
