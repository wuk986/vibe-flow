# vibe-flow rules

The plugin's `SessionStart` hook loads them into every session in a project whose CLAUDE.md has a `## vibe-flow` section, also outside the skills:

- **Board**: only `/vibe-flow:issue`, `/vibe-flow:work`, and `/vibe-flow:done` change issues, statuses, and PRs. A status changes only inside these skills: Review means gate and review ran, so it is reached through `/vibe-flow:work`. For anything else on the board, ask the user first. An OK covers exactly what was named.
- **User files**: ask before deleting or moving files the user placed in the project, even when they are committed.
- **Principles**: follow `${CLAUDE_PLUGIN_ROOT}/PRINCIPLES.md` for every code change.
