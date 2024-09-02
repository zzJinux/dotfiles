#!/usr/bin/env bash

set -euo pipefail

if [ -z "${OFFLINE-}" ]; then
  # Get a file URL from https://invisible-island.net/archives/ncurses/current/terminfo-{LATEST}.src.gz
  file_url="$1"
  asc_url="${file_url}.asc"

  # Download the file and its signature, and verify the signature
  curl -LO "$file_url"
  curl -LO "$asc_url"
  filename="${file_url##*/}"
  # https://invisible-island.net/public/public.html
  gpg --keyserver keyserver.ubuntu.com --recv-keys '19882D92DDA4C400C22C0D56CC2AF4472167BE03'
  gpg --verify "${asc_url##*/}" "$filename"

else
  filename="$1"
fi

# Extract the file
gunzip "$filename"
filename="${filename%.gz}"

# Install the extracted file
/usr/bin/tic -xe iterm2,vscode "$filename"