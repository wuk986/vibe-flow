---
name: issue
description: Create a kanban issue from the user's description, with goal, acceptance criteria, and labels, in Backlog.
disable-model-invocation: true
argument-hint: <description>
---

# issue

Turns the user's description into a well-formed issue on the board. The description is the user's; your job is to make it checkable.

## Steps

1. **Load context** as described in `~/.claude/vibe-flow/CONVENTIONS.md`.
2. **Understand**: read the description. Read only as much code as you need to make the acceptance criteria concrete. Search open issues for duplicates (adapter: Find duplicates); show a likely duplicate and ask before going on.
3. **Draft**, in the Kanban language:
   - **Title**: imperative, under 70 characters.
   - **Body** with three sections:
     - *Goal*: one or two sentences on what changes for whom and why.
     - *Acceptance criteria*: a checklist; each item observable and checkable, since `/work` turns each one into a test.
     - *Out of scope*: what this issue deliberately leaves out; omit the section when nothing is.
   - **Type**: exactly one of `bug`, `feature`, `chore`.
   - **Area**: matching `area/` labels from the repo's existing set; a missing one only as a proposal.
   - **Milestone**: only when the user named one.
4. **Clarify**: ask at most three questions, and only about gaps that would change the acceptance criteria. Then show the full draft with labels and wait for the user's OK or corrections.
5. **Create**: on OK, create any new area label or milestone the user approved, then the issue (adapter: Create issue), then set its status to Backlog.
6. **Report** the issue number and URL.
