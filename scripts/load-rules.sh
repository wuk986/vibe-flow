#!/usr/bin/env bash
# SessionStart hook: prints the vibe-flow rules as session context when the project's CLAUDE.md
# has a "## vibe-flow" section. Prints nothing otherwise, so other projects stay untouched.
set -euo pipefail

root=${CLAUDE_PLUGIN_ROOT:?}
root=${root//\\//}  # forward slashes, also when Windows passes backslashes
claude_md="${CLAUDE_PROJECT_DIR:-$PWD}/CLAUDE.md"

[ -f "$claude_md" ] && grep -q '^## vibe-flow[[:space:]]*$' "$claude_md" || exit 0

echo "This project uses the vibe-flow plugin (installed at $root). Its project rules follow."
echo
rules=$(cat "$root/rules/vibe-flow.md")
placeholder='${CLAUDE_PLUGIN_ROOT}'
# Bash substitution, not sed: a path's backslashes or & stay literal.
printf '%s\n' "${rules//"$placeholder"/"$root"}"
