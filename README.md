# vibe-flow

A kanban-driven vibe coding workflow for Claude Code, usable in any project. The board (GitHub Projects or Forgejo) is the source of truth: the issue, the plan, the work done, and the manual test instructions all live there.

```
/vibe-flow:issue → Backlog → /vibe-flow:work → In Progress → Review → (manual check) → /vibe-flow:done → Done
                                                   ↑                 │
                                                   └── /vibe-flow:work <n> <feedback>
```

| Command | What it does |
|---|---|
| `/vibe-flow:setup` | CLAUDE.md (via `/init` if missing), board with 4 columns, labels, test/lint commands, languages, optional graphify |
| `/vibe-flow:issue <description>` | Planner analysis with questions until nothing is open; issue with goal, acceptance criteria, out of scope, approach, risks, assets, labels; added to Backlog after your OK |
| `/vibe-flow:work [#n] [feedback]` | Branch, plan comment, test-first implementation, risk-based review, green tests + lint, PR, hand-over comment, Review |
| `/vibe-flow:done [#n]` | After your manual check: squash-merge, close the issue, Done |

## Install

```bash
claude plugin marketplace add wuk986/vibe-flow
claude plugin install vibe-flow@vibe-flow
```

Then run `/vibe-flow:setup` once in each project. The plugin updates itself; re-run `/vibe-flow:setup` in a project when the CLAUDE.md section in CONVENTIONS.md has changed. Rule changes take effect with the next session, without touching the project.

### Moving from 1.x

1.x was installed with `install.sh` or `install.ps1`, which linked files into `~/.claude`. Those links would load every skill a second time next to the plugin, so remove them after installing the plugin:

- `~/.claude/skills/init-project`, `~/.claude/skills/issue`, `~/.claude/skills/work`, `~/.claude/skills/done`
- `~/.claude/rules/vibe-flow`
- `~/.claude/vibe-flow` (the clone or its link)

`/vibe-flow:setup` lists the ones it still finds. The project's `## vibe-flow` CLAUDE.md section stays as it is. The commands now carry the `vibe-flow:` prefix, and `/init-project` is now `/vibe-flow:setup`.

## Models

`/vibe-flow:issue` and `/vibe-flow:work` run planning, building, and review in subagents on models matched to the issue's risk class; stuck steps escalate one level, and after two final review rounds with open findings the run stops and you decide. The model assignment lives in one place: [skills/work/SKILL.md](skills/work/SKILL.md).

## Files

- [PRINCIPLES.md](PRINCIPLES.md): coding principles (after [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)), their single source
- [rules/vibe-flow.md](rules/vibe-flow.md): the rules loaded into every session of a vibe-flow project, through the hook in [hooks/](hooks/)
- [CONVENTIONS.md](CONVENTIONS.md): statuses, assets, labels, risk classes, languages, the CLAUDE.md section
- [REVIEW.md](REVIEW.md): the review checklist
- [forges/](forges/): adapters for GitHub (`gh`) and Forgejo (REST, plus Claude in Chrome for the board)
- [skills/](skills/): the four skills
- [agents/](agents/): the subagent roles `/vibe-flow:work` orchestrates; planner, reviewer, and helper cannot edit files

## Requirements

- **Claude Code** with plugin support; on Windows, Git Bash (the rules hook and the GitHub board script are Bash)
- **GitHub:** `gh`, logged in, with the `project` scope (`gh auth refresh -s project`)
- **Forgejo:** environment variable `FORGEJO_TOKEN`, `curl`; Claude in Chrome for the board
- **Optional:** [graphify](https://pypi.org/project/graphifyy/) (`uv tool install graphifyy`)
