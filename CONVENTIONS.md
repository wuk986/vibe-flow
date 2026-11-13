# vibe-flow conventions

Shared reference for the vibe-flow skills `/vibe-flow:setup`, `/vibe-flow:issue`, `/vibe-flow:work`, `/vibe-flow:done`, `/vibe-flow:review`; below they are named without the `vibe-flow:` prefix. The kanban board is the source of truth: everything about an issue and the work done on it lives there, nothing is mirrored into repo files.

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

- Forge: github | forgejo | gitea
- Board: <GitHub project number | Gitea project id | Forgejo or older Gitea project board URL, or none>
- Test: `<command>`
- Lint: `<command>` | none
- Kanban language: <language>
- Commit language: <language>
```

The rules that must hold outside the skills too live in `rules/vibe-flow.md`. The plugin's `SessionStart` hook adds them to every session in a project with this section, so a rule change needs no commit in the project.

## Board

Four statuses, in order. On GitHub and on Gitea 28.0.0 or later the status lives only in the board column. On Forgejo and older Gitea, which have no board API, it lives in one `status/` label per open issue, and Done is the closed issue; the board there is a view the adapter keeps up when it can.

| Status | Set by | Meaning |
|---|---|---|
| Backlog | `/issue` | Described, not started |
| In Progress | `/work` | Being worked on |
| Review | `/work` | Reviewed, tests and lint green, PR open, waiting for the user's manual check |
| Done | `/done` | User checked it; merged and closed |

Several issues may sit in In Progress, each in its own worktree (see Git).

A withdrawn issue is closed without a merge (adapter: Close issue) and taken off the board (adapter: Remove from board, which on every forge leaves the issue itself alone); no status fits it. A review issue from `/review` never gets a status: it holds the report and is closed by `/review` itself.

## Assets

Files that belong to an issue, such as mockups and screenshots, are listed in the issue body under *Assets* with their repo path. `/work` copies them from the main checkout into the issue's worktree and commits them on the issue branch, so they land with the issue's PR. List only final files that an acceptance criterion or a reviewer needs. Drafts stay out of the repo; large raw files such as PSDs or videos stay out too and are linked in the issue.

## Labels

- **Type**, exactly one per issue. It decides the test strategy in `/work`.
  - `bug`: existing behavior is wrong.
  - `feature`: new or changed behavior.
  - `chore`: no behavior change (refactoring, dependencies, config, CI, docs).
- **Area**, zero or more: `area/<topic>`, e.g. `area/ui-ux`. Use the repo's existing area labels. When none fits, propose a new one and create it only after the user agrees.
- **Risk**, exactly one per issue: `risk/low`, `risk/normal`, or `risk/high`. See Risk.
- **Status**, only where the status lives in labels (Forgejo, Gitea before 28.0.0): `status/backlog`, `status/in-progress`, `status/review`; at most one per issue, set only through the adapter. See Board.
- **Milestone**, optional: set only when the user names one. A missing milestone is created only after the user agrees.

`/setup` creates the labels vibe-flow defines with these descriptions and brings existing ones in line:

| Label | Description |
|---|---|
| `bug` | Existing behavior is wrong |
| `feature` | New or changed behavior |
| `chore` | No behavior change |
| `risk/low` | Risk class low: fast path, one light review |
| `risk/normal` | Risk class normal: full review |
| `risk/high` | Risk class high: full review with failure modes |
| `status/backlog` | Status: described, not started |
| `status/in-progress` | Status: being worked on |
| `status/review` | Status: waiting for the manual check |

## Risk

Every issue carries a risk class as its `risk/` label. It decides which models review and whether `/work` may take its fast path.

1. `/issue` sets the label from the planner's estimate, once the user has confirmed the draft. The user may change it at any time.
2. `/work` starts from the label and may only raise it: when the planner or a reviewer finds a criterion of a higher class, `/work` replaces the label and states the reason on the issue. Lowering it is the user's call. An issue without a risk label, such as one created before vibe-flow 2.1, gets the planner's class as its label.

The criteria:
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
- Worktree per issue: `../<repo>.worktrees/<n>-<slug>`, next to the main checkout, where `<repo>` is the main checkout's folder name. `/work` creates or reuses it and does every git operation and every role's work there; `/done` removes it. The main checkout keeps its branch and is never switched. The worktree lies outside the repo, so test runners, linters, and graphify do not scan it.
- Commits: `#<n>: <imperative summary>`, small steps; `/done` squashes them.
- Pass multi-line text (bodies, comments) to CLI and API calls through a temp file outside the repo, never inline.
