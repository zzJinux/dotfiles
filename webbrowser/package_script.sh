#!/usr/bin/env bash
set -euo pipefail
# stdin to stdout
printf 'data:text/html,<script>'
sed 's/?/%3F/g' | sed 's/{/%7B/g' | sed 's/PLACEHOLDER_SEARCH_TERMS/{searchTerms}/g'
printf '</script>'
# Optionally pipe to `jq -R` to get the escaped version