# vibe-flow conventions

Shared reference for the vibe-flow skills `/init-project`, `/issue`, `/work`, `/done`. The kanban board is the source of truth: everything about an issue and the work done on it lives there, nothing is mirrored into repo files.

## Load context

Every skill except `/init-project` starts here:

1. Read the `## vibe-flow` section of the project's CLAUDE.md. Missing or incomplete → stop and tell the user to run `/init-project`.
2. Read the adapter for the configured forge, `~/.claude/vibe-flow/forges/<forge>.md`. Every issue, label, board, and PR operation goes through it.
3. Owner, repo, and host come from `git remote get-url origin`.

## CLAUDE.md section

The single place for per-project settings. `/init-project` writes it in exactly this shape; the other skills only read it.

```markdown
## vibe-flow

- Forge: github | forgejo
- Board: <GitHub project number | Forgejo project board URL>
- Test: `<command>`
- Lint: `<command>` | none
- Kanban language: <language>
- Commit language: <language>
- Principles: follow ~/.claude/vibe-flow/PRINCIPLES.md for every code change.
```

## Board

Four statuses, in order. The status lives only in the board column.

| Status | Set by | Meaning |
|---|---|---|
| Backlog | `/issue` | Described, not started |
| In Progress | `/work` | Being worked on |
| Review | `/work` | Reviewed, tests and lint green, PR open, waiting for the user's manual check |
| Done | `/done` | User checked it; merged and closed |

Several issues may sit in In Progress; only the checked-out branch is actively worked on.

## Labels

- **Type**, exactly one per issue. It decides the test strategy in `/work`.
  - `bug`: existing behavior is wrong.
  - `feature`: new or changed behavior.
  - `chore`: no behavior change (refactoring, dependencies, config, CI, docs).
- **Area**, zero or more: `area/<topic>`, e.g. `area/ui-ux`. Use the repo's existing area labels. When none fits, propose a new one and create it only after the user agrees.
- **Risk override**, optional: `risk/high` or `risk/low`, set only by the user. See Risk.
- **Milestone**, optional: set only when the user names one. A missing milestone is created only after the user agrees.

## Risk

Every issue gets a risk class in `/work`; it decides which models review.

1. A `risk/high` or `risk/low` label on the issue wins.
2. Otherwise the planner classifies:
   - **high**: the change touches security, authentication, permissions, or secrets; the data model, migrations, or possible data loss; concurrency, caching, or transactions; a public interface others use (API, CLI, file format); or the diff is large (about 10+ files or several modules).
   - **low**: a `chore` or a small mechanical change with no behavior change.
   - **normal**: everything else.

## Language

- Board text (issue title and body, comments, PR title and body) and messages to the user: **Kanban language**.
- Commit messages and branch slugs: **Commit language**.
- Code, identifiers, and code comments: follow the existing codebase.

## Git

- Branch per issue: `<n>-<slug>`, e.g. `12-login-timeout`.
- Commits: `#<n>: <imperative summary>`, small steps; `/done` squashes them.
- Pass multi-line text (bodies, comments) to CLI and API calls through a temp file outside the repo, never inline.
