---
name: issue
description: Plan a kanban issue from the user's description - planner analysis, open questions, goal, criteria, approach, risks - and create it in Backlog.
disable-model-invocation: true
argument-hint: <description>
---

# issue

Turns the user's description into a planned issue on the board. The description is the user's; your job is to make it checkable and to surface problems and open points before any work starts.

## Steps

1. **Load context** as described in `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md`; `<plugin root>` there is `${CLAUDE_PLUGIN_ROOT}`.
2. **Duplicates**: search open issues (adapter: Find duplicates); show a likely duplicate and ask before going on.
3. **Analyze**: spawn the planner (see Subagents in CONVENTIONS.md) on its default model in mode `issue`. It returns `QUESTIONS` → ask the user, wait, and continue the same planner with the answers, until it returns its analysis.
4. **Draft**, in the Kanban language, from the analysis:
   - **Title**, **Type**, **Area**.
   - **Body**: *Goal*, *Acceptance criteria*, *Out of scope*, *Approach*, *Risks*; omit a section that is empty. Add *Assets* with the repo paths of files the user provides, and `Depends on: #<m>` when the issue needs another one first.
   - **Milestone**: only when the user named one.
5. **Show** the full draft with labels and the risk estimate with its reason; the estimate becomes the issue's `risk/` label (CONVENTIONS.md, Risk), so the user may correct it here. A proposed split comes with it. Wait for the user's OK or corrections.
6. **Create**: on OK, create any new area label or milestone the user approved, then the issue or issues in order (adapter: Create issue) with their type, area, and `risk/` labels, then set each status to Backlog (adapter: Set status), which also puts the issue on the board.
7. **Report** the issue numbers and URLs.
