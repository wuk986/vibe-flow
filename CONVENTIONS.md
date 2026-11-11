# vibe-flow conventions

Shared reference for the vibe-flow skills `/vibe-flow:setup`, `/vibe-flow:issue`, `/vibe-flow:work`, `/vibe-flow:done`; below they are named without the `vibe-flow:` prefix. The kanban board is the source of truth: everything about an issue and the work done on it lives there, nothing is mirrored into repo files.

## Plugin root

`<plugin root>` stands for the directory the vibe-flow plugin is installed in. Every skill names it where it loads this file; paths in this file and in the adapters are relative to it.

## Load context

Every skill except `/setup` starts here:

1. Read the `## vibe-flow` section of the project's CLAUDE.md. Missing or incomplete → stop and tell the user to run `/vibe-flow:setup`.
2. Read the adapter for the configured forge, `<plugin root>/forges/<forge>.md`. Every issue, label, board, and PR operation goes through it.
3. Owner, repo, and host come from `git remote get-url origin`.

## CLAUDE.md section

The single place for per-project settings. `/setup` writes it in exactly this shape; the other skills only read it.

```markdown
## vibe-flow

- Forge: github | forgejo
- Board: <GitHub project number | Forgejo project board URL>
- Test: `<command>`
- Lint: `<command>` | none
- Kanban language: <language>
- Commit language: <language>
```

The rules that must hold outside the skills too live in `rules/vibe-flow.md`. The plugin's `SessionStart` hook adds them to every session in a project with this section, so a rule change needs no commit in the project.

## Board

Four statuses, in order. The status lives only in the board column.

| Status | Set by | Meaning |
|---|---|---|
| Backlog | `/issue` | Described, not started |
| In Progress | `/work` | Being worked on |
| Review | `/work` | Reviewed, tests and lint green, PR open, waiting for the user's manual check |
| Done | `/done` | User checked it; merged and closed |

Several issues may sit in In Progress; only the checked-out branch is actively worked on.

A withdrawn issue is closed without a merge and removed from the board (adapter: Remove from board); no status fits it.

## Assets

Files that belong to an issue, such as mockups and screenshots, are listed in the issue body under *Assets* with their repo path. `/work` commits them on the issue branch, so they land with the issue's PR. List only final files that an acceptance criterion or a reviewer needs. Drafts stay out of the repo; large raw files such as PSDs or videos stay out too and are linked in the issue.

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
   - **high**: the change touches security, authentication, permissions, or secrets; the data model, migrations, or possible data loss; concurrency, caching, or transactions; a change that can break existing users of a public interface (API, CLI, file format), while a purely additive one does not count; or the diff is large (about 10+ files or several modules).
   - **low**: a `chore` or a small mechanical change with no behavior change.
   - **normal**: everything else.

## Language

- Board text (issue title and body, comments, PR title and body) and messages to the user: **Kanban language**.
- Commit messages and branch slugs: **Commit language**.
- Code, identifiers, and code comments: follow the existing codebase.

## Subagents

Each role is a plugin agent: spawn it with subagent type `vibe-flow:<role>` (`planner`, `worker`, `reviewer`, `helper`). Its prompt carries the inputs `<plugin root>/agents/<role>.md` lists. The agent's frontmatter sets its default model; pass `model` only where a skill assigns a different one. Continue a running subagent with SendMessage instead of spawning a new one.

## Git

- Branch per issue: `<n>-<slug>`, e.g. `12-login-timeout`.
- Commits: `#<n>: <imperative summary>`, small steps; `/done` squashes them.
- Pass multi-line text (bodies, comments) to CLI and API calls through a temp file outside the repo, never inline.
