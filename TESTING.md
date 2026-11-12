# Testing vibe-flow

A manual test plan for vibe-flow itself. Run it before each release: copy the checklists below into an issue titled `Release test <version>` in this repo and tick them there, so every version keeps its own record. Note anything unexpected in the issue as a finding.

## Setup

You need a sandbox repo per forge you test: a small project with a test command, a linter, and a few tests (for example a tiny CLI), and nothing you would mind losing.

| Forge | Sandbox | Token |
|---|---|---|
| GitHub | a repo plus a GitHub Projects board | `gh` logged in with the `project` scope |
| Forgejo | a repo on any Forgejo instance | `FORGEJO_TOKEN` |
| Gitea 28 or later | a repo on a Gitea instance with the project board API | `GITEA_TOKEN` |

Load the version under test before you start, in a fresh session:

- From a branch: point the `vibe-flow` marketplace at your local clone (`claude plugin marketplace add <path to clone>`, after removing the GitHub one), check out the branch there, and start a new session. Switch the marketplace back to `wuk986/vibe-flow` afterwards.
- From a release: `claude plugin marketplace update vibe-flow`, then a new session.

`claude plugin details vibe-flow@vibe-flow` must show the version under test.

## Plugin

- [ ] **Components**: `claude plugin details vibe-flow@vibe-flow` lists 4 skills (`done`, `issue`, `setup`, `work`), 4 agents, and the `SessionStart` hook. `claude plugin validate <clone>` passes.
- [ ] **Rules hook**: in a new session in the sandbox, ask whether the context says the project uses the vibe-flow plugin. Expected: yes, with the rules and a `PRINCIPLES.md` path inside the plugin. In a project without a `## vibe-flow` section: no such context.
- [ ] **Read-only agents**: ask the session to spawn `vibe-flow:helper` and let it try to create a file with Write. Expected: it has no Edit, Write, or NotebookEdit, and no file appears. `vibe-flow:worker` can write.

## `/vibe-flow:setup`

- [ ] **Fresh project**: in a repo without a `## vibe-flow` section. Expected: asks for the two languages, finds and runs Test and Lint, sets up the board, creates the labels from CONVENTIONS.md, writes the CLAUDE.md section, and asks before committing.
- [ ] **Re-run**: run it again. Expected: shows the current values and keeps them, changes nothing that is already right, and aligns label descriptions that differ (e.g. an old "Risk override" text) while keeping the colors.
- [ ] **Forge detection**: on Forgejo and on Gitea, the forge is recognized from `/api/v1/version` and confirmed with you.
- [ ] **1.x leftovers**: with a leftover link such as `~/.claude/skills/work` from a 1.x install, setup lists it and deletes nothing.

## `/vibe-flow:issue`

- [ ] **Small chore**: `/vibe-flow:issue <a one-file docs change>`. Expected: duplicate search, planner questions with recommended answers if anything is open, a draft with goal, criteria, out of scope, approach, risks, and the risk estimate; after your OK the issue exists with its type, area, and `risk/low` label, in Backlog. File paths in the issue are relative to the repo root.
- [ ] **Risk correction**: change the estimate in the draft. Expected: the issue gets the label you chose.
- [ ] **New area label**: a description that fits no existing area. Expected: a proposed `area/` label, created only after your OK.

## `/vibe-flow:work`

- [ ] **Fast path**: on the `risk/low` issue with an Approach. Expected: no planner; a plan comment shaped `PLAN (fast path)`; a sonnet worker; gate green; one sonnet `light` review with effort medium; status Review.
- [ ] **Worktree**: during the run, `git worktree list` shows `../<repo>.worktrees/<n>-<slug>`, and the main checkout keeps its branch and stays untouched. The branch tracks its own remote branch after the push (`git -C <worktree> status -sb`).
- [ ] **Normal risk**: on a `feature` issue. Expected: a planner on opus with effort high, no intermediate review, an opus `full` final review with effort high, R2 only when R1 had findings.
- [ ] **High risk**: on an issue touching e.g. input validation of a public interface. Expected: a planner on opus with effort xhigh, a sonnet `light` intermediate review, and a fable `full` final review; or the fallback, an opus `full` review with effort xhigh whose report answers every checklist item, with its reason in the hand-over.
- [ ] **Escalation**: an issue whose test the worker cannot get green. Expected: after the second red gate with the same reason the worker runs once on opus with effort high; still red → ❌ with the failing test, no further attempt.
- [ ] **Risk raised**: an issue labeled `risk/low` whose change turns out to touch a high-risk criterion. Expected: the label is raised and the reason is posted; it is never lowered.
- [ ] **Resume with feedback**: `/vibe-flow:work <n> <feedback>` on an issue in Review. Expected: a *Feedback from manual check* comment, the existing worktree is reused, the plan covers only the feedback.
- [ ] **Parallel issues**: start a second issue while the first is in Review. Expected: a second worktree; the first stays untouched.
- [ ] **1.x branch**: an issue branch checked out in the main checkout. Expected: `/work` stops and asks you to switch the main checkout first.

### Verdict

- [ ] **✅**: a normal run. Expected: the first line of the hand-over comment and of the last message is the ✅ verdict naming the steps you still have to check yourself; status Review.
- [ ] **⏳**: a sandbox with a CI workflow that runs longer than 10 minutes. Expected: the ⏳ verdict naming the pending checks; status Review; `/vibe-flow:done` waits for the checks before merging.
- [ ] **❌ conflict**: while `/work` runs, push a commit to the default branch that changes the same lines. Expected: the merge is aborted, the ❌ verdict names the conflicting files and the next move; status stays In Progress.
- [ ] **❌ failed check**: a CI workflow that fails. Expected: ❌ naming the failing check.
- [ ] **❌ after R2**: when must-fix findings stay open after R2 (record it when it happens). Expected: one comment with exactly those findings and the ❌ verdict.
- [ ] **No auto-done**: in no case does `/work` run `/vibe-flow:done`.

## `/vibe-flow:done`

- [ ] **Merge and close**: after your manual check. Expected: squash-merge with `#<n>: <title>` in the commit language, remote branch deleted, criteria ticked, closing comment, issue closed and in Done.
- [ ] **Cleanup**: the worktree is removed, the `../<repo>.worktrees` folder too once it is empty, the local branch is deleted, and the main checkout is pulled only when it is on the default branch.
- [ ] **Dirty worktree**: leave an uncommitted change in the worktree. Expected: `/done` merges, then stops at the worktree and shows the change.

## Forges

- [ ] **Forgejo**: the status lives in `status/` labels set over REST; Done is the closed issue; with `Board: none` no Chrome step runs; with a board URL the board view is updated through Claude in Chrome, or you get the manual step in one line.
- [ ] **Gitea 28 or later**: the status lives in the repo's project board, set over the API, like GitHub. (Planned: the Gitea board adapter.)
- [ ] **Gitea before 28**: falls back to the Forgejo label path. Not tested regularly.
