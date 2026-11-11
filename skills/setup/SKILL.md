---
name: setup
description: Set up the current project for the vibe-flow kanban workflow (CLAUDE.md section, board, labels, tests, graphify).
disable-model-invocation: true
---

# setup

Prepares the project for `/vibe-flow:issue`, `/vibe-flow:work`, and `/vibe-flow:done`. Re-running it updates the existing setup in place.

Read `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md` first; `<plugin root>` there is `${CLAUDE_PLUGIN_ROOT}`. It defines the CLAUDE.md section, statuses, and labels set up here.

## Steps

1. **CLAUDE.md**: when the project has none, invoke the built-in `init` skill first. Done when CLAUDE.md exists.
2. **Repository**: the project must be a git repo with an `origin` remote. Without a remote, ask the user for the forge and offer to create a private repo (adapter: Create repo).
3. **Forge**: `github.com` in the remote → `github`. Any other host → ask the user; vibe-flow supports `github` and `forgejo`. Read the adapter `${CLAUDE_PLUGIN_ROOT}/forges/<forge>.md` and verify access (GitHub: `gh auth status`; Forgejo: Check access).
4. **Languages**: ask the user for the Kanban language and the Commit language. On a re-run, show the current values and keep them unless the user changes them.
5. **Test and lint**: find the commands in the environment (package scripts, pyproject, Makefile, CI config) and run each once. Show commands and results; the user confirms them.
   - No test setup → propose the standard minimal framework for the language with one smoke test; set it up after the user agrees. `/work` needs a green suite to reach Review.
   - No linter → ask whether to set one up or record `none`.
6. **Board**: set up the board with the adapter (Set up board). Done when the adapter's Set up board says so.
7. **Labels**: create the labels from the table in CONVENTIONS.md, Labels (the `status/` ones on Forgejo only), with their descriptions. A label that already exists keeps its color; when its description differs, for example the 1.x "Risk override" text, update it (adapter: Create label on GitHub, Update label on Forgejo). Propose 3–6 `area/` labels derived from the codebase's structure; create what the user confirms. Existing labels stay.
8. **graphify**: when `graphify-out/` is missing, ask whether to set up graphify for this project. On yes, run `graphify claude install`, which writes the `## graphify` section into CLAUDE.md, and invoke the `graphify` skill to build the graph. When `graphify` is not on PATH, tell the user to install it (`uv tool install graphifyy`) and continue. Either way, add `graphify-out/` to `.gitignore`: it is generated, a CLAUDE.md in a parent folder can create it even when graphify was declined, and an untracked folder would stop `/work`. When it is already tracked, untrack it with `git rm -r --cached graphify-out`; the files stay on disk.
9. **CLAUDE.md section**: write the `## vibe-flow` section as defined in CONVENTIONS.md. In an existing section, update the defined fields in place and remove the retired lines `Principles`, `Board rule`, `User files`, and `Rules`; everything else the project wrote there stays. Done when CLAUDE.md contains exactly one such section with every field filled. The rules reach the project's sessions through the plugin's `SessionStart` hook, starting with the next session.
10. **Old install**: check for links left by the 1.x install scripts: `~/.claude/skills/init-project`, `~/.claude/skills/issue`, `~/.claude/skills/work`, `~/.claude/skills/done`, `~/.claude/rules/vibe-flow`, `~/.claude/vibe-flow`. List each one that exists and is a symlink or junction into a vibe-flow clone, and tell the user to remove them, since they load every skill a second time next to the plugin. Delete nothing yourself.
11. **Commit**: show a summary of what changed and ask whether to commit (`chore: set up vibe-flow`, in the Commit language) and push.
