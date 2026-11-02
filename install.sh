#!/usr/bin/env bash
# Links vibe-flow into ~/.claude (Linux, macOS): the repo as ~/.claude/vibe-flow, each skill as ~/.claude/skills/<name>.
set -euo pipefail

src=$(cd "$(dirname "$0")" && pwd)
claude="$HOME/.claude"
mkdir -p "$claude/skills"

link() { # <target> <link path>
  if [ -L "$2" ]; then
    rm "$2"
  elif [ -e "$2" ]; then
    echo "skipped: $2 exists and is not a link" >&2
    return
  fi
  ln -s "$1" "$2"
  echo "linked $2 -> $1"
}

[ "$src" = "$claude/vibe-flow" ] || link "$src" "$claude/vibe-flow"
for skill in "$src"/skills/*/; do
  link "${skill%/}" "$claude/skills/$(basename "$skill")"
done
