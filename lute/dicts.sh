#!/bin/sh
#
# Download the reader-dict dictionaries Lute uses, skipping any already present.
# Usage: dicts.sh [DIR]   (default ~/Documents/Dictionaries)

set -e
DICTS="${1:-$HOME/Documents/Dictionaries}"
mkdir -p "$DICTS"

for d in \
  "dict-fr-en.df https://www.reader-dict.com/file/01a0f36a13a7d43957025ea15403e62c" \
  "dict-fr-fr.df https://www.reader-dict.com/file/fr/dict-fr-fr-noetym.df.bz2"; do
  set -- $d
  [ -s "$DICTS/$1" ] && continue
  echo "Downloading $1..."
  # Write to a temp file so an interrupted download never leaves a partial dictionary.
  rm -f "$DICTS/$1.part.bz2"
  curl -fL --progress-bar -o "$DICTS/$1.part.bz2" "$2"
  bunzip2 "$DICTS/$1.part.bz2"
  mv "$DICTS/$1.part" "$DICTS/$1"
done
