# vibe-flow

A kanban-driven vibe coding workflow for Claude Code, usable in any project. The board (GitHub Projects or Forgejo) is the source of truth: the issue, the plan, the work done, and the manual test instructions all live there.

```
/issue → Backlog → /work → In Progress → Review → (manual check) → /done → Done
                              ↑                 │
                              └── /work <n> <feedback>
```

| Command | What it does |
|---|---|
| `/init-project` | CLAUDE.md (via `/init` if missing), board with 4 columns, labels, test/lint commands, languages, optional graphify |
| `/issue <description>` | Issue with goal, acceptance criteria, out of scope, type and area labels; added to Backlog after your OK |
| `/work [#n] [feedback]` | Branch, plan comment, test-first implementation, self-review, green tests + lint, PR, hand-over comment, Review |
| `/done [#n]` | After your manual check: squash-merge, close the issue, Done |

## Files

- [PRINCIPLES.md](PRINCIPLES.md): coding principles (after [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)), their single source
- [CONVENTIONS.md](CONVENTIONS.md): statuses, labels, languages, the CLAUDE.md section
- [forges/](forges/): adapters for GitHub (`gh`) and Forgejo (REST, plus Claude in Chrome for the board)
- [skills/](skills/): the four skills

## Install

```bash
git clone https://github.com/wuk986/vibe-flow.git ~/.claude/vibe-flow
```

Linux/macOS:

```bash
bash ~/.claude/vibe-flow/install.sh
```

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File $HOME\.claude\vibe-flow\install.ps1
```

The script links the skills into `~/.claude/skills` (symlinks or junctions). A clone kept elsewhere is additionally linked as `~/.claude/vibe-flow`. Update with `git pull`; re-run the script when a new skill is added.

## Requirements

- **GitHub:** `gh`, logged in, with the `project` scope (`gh auth refresh -s project`)
- **Forgejo:** environment variable `FORGEJO_TOKEN`, `curl`; Claude in Chrome for the board
- **Optional:** [graphify](https://pypi.org/project/graphifyy/) (`uv tool install graphifyy`)
