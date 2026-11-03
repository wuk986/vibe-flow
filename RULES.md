# vibe-flow rules

Always loaded through the project's CLAUDE.md, also outside the skills.

- **Board**: only `/issue`, `/work`, and `/done` change issues, statuses, and PRs. A status changes only inside these skills: Review means gate and review ran, so it is reached through `/work`. For anything else on the board, ask the user first. An OK covers exactly what was named.
- **User files**: ask before deleting or moving files the user placed in the project, even when they are committed.
- **Principles**: follow `~/.claude/vibe-flow/PRINCIPLES.md` for every code change.
