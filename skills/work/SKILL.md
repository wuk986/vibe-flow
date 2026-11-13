---
name: work
description: Work a kanban issue end to end - plan, build test-first, risk-based review, green gate, PR, move to Review.
disable-model-invocation: true
argument-hint: "[#n] [feedback from manual check]"
---

# work

Takes one issue from Backlog (or back from Review with feedback) to Review: gate green, PR open, everything documented on the issue. You are the **orchestrator**: you talk to the board and the user and steer the subagents; planning, building, and reviewing run in subagents on the model this skill assigns. Work autonomously; stop for the user only where a step says so. Two kinds of stop: **ask** (a question for the user; wait for the answer, then carry on) and **end** (the run is over). Every run that got past step 1 ends with a verdict (step 8), also one that ends early; steps 1.3 and 1.4 end without one, since nothing ran.

## Subagents

Spawn each role as described in Subagents in CONVENTIONS.md, with the `model` and `effort` named here. This table and the risk table below are the only place that assigns models for `/work`; `/vibe-flow:review` has its own table. The README links here.

| Role | Model | Used for |
|---|---|---|
| planner | `opus` | planning in step 3 |
| worker | `sonnet` | building and every fix |
| reviewer-light | `sonnet`, mode `light` | the low-risk final review, the high-risk intermediate review |
| reviewer | `opus` (normal) or `fable` (high), mode `full` | the final review |
| reviewer-fallback | `opus`, mode `full` with the checklist | the final review when fable is unavailable (step 5) |
| helper | `haiku` | only the mechanical gate and scope checks |

All three reviewer roles are the `vibe-flow:reviewer` agent with the model, effort, and mode given here.

**Risk**: the higher the risk class, the stronger the planner and the reviewers:

| Risk | Planner | Intermediate review | Final review R1 and R2 |
|---|---|---|---|
| low | none on the fast path, else `opus`, effort `medium` | none | reviewer-light: `sonnet`, effort `medium` |
| normal | `opus`, effort `high` | none | reviewer: `opus`, effort `high` |
| high | `opus`, effort `xhigh` | reviewer-light: `sonnet`, effort `medium` | reviewer: `fable`, effort `high`; fallback: reviewer-fallback, `opus`, effort `xhigh` |

The worker and the helper run without an effort setting, at their default. **A reviewer is never weaker than the worker**: once the worker has run escalated on `opus`, every later review that this table puts on `sonnet` runs on `opus` instead, with the same mode and effort.

Every role gets the absolute path of the issue's worktree as input and works only there. A subagent's report is a claim. The gate verdict that counts is the helper's.

**Escalation** raises a role once per run by one level in model and effort: `sonnet` → `opus` with effort `high`; a role already on `opus` or `fable` keeps its model and gets the next effort (`medium` → `high` → `xhigh` → `max`). It applies to the worker when the gate is red twice for the same `Reason`, when the same finding ID appears in two reviews in a row, or when it reports `BLOCKED`; to a reviewer when it reports `BLOCKED`. An escalated role stays escalated for the rest of the run. A `BLOCKED` that needs information only the user has → ask the user instead. Fable is never an escalation level.

**After the escalation: stop and report.** A second trigger for a role that is already escalated (the gate still red, a `BLOCKED` again) → end with ❌ (step 8): post what failed (the failing test with the helper's `Reason`, or the blocker) as an issue comment and lay it out for the user. There is no second escalation.

## 1. Pick the issue

1. **Load context** as described in `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md`; `<plugin root>` there is `${CLAUDE_PLUGIN_ROOT}`.
2. No issue number given → list the Backlog issues (number, title, type) and ask which one.
3. Read the issue: body, labels, every comment. A closed issue or one in Done → stop and say so.
4. Its `Depends on: #<m>` names an open issue → stop and say which one.

## 2. Prepare

The worktree `<wt>` is `../<repo>.worktrees/<n>-<slug>` (CONVENTIONS.md, Git). From here on, every git command for the issue runs in `<wt>`; the main checkout stays as it is.

1. Other issues in In Progress → mention them in one line and continue. Fetch, so the remote branches below are current.
2. `<wt>` exists → **resume**: `git status` there shows uncommitted changes → ask the user how to proceed; their changes are theirs to commit or discard. Otherwise, when the branch has an upstream (`git rev-parse @{u}` succeeds), `git pull --ff-only` in `<wt>`; without one, as after a run that ended before its push, there is nothing to pull.
3. No `<wt>`, but branch `<n>-<slug>` exists locally or on the remote → **resume**: `git worktree add <wt> <n>-<slug>`, then pull there as in 2. The branch is checked out in the main checkout, as vibe-flow 1.x left it → git refuses; ask the user to switch the main checkout to another branch first, after committing or stashing what is open there. Neither exists → `git worktree add --no-track -b <n>-<slug> <wt> origin/<default>`; without `--no-track` the branch would track the default branch, and a plain `git push` would miss its own remote branch.
4. A new worktree has none of the main checkout's untracked files. When the Test or Lint command needs installed dependencies, run the project's install step in `<wt>` (e.g. `npm ci`, `uv sync`). Local configuration that the tests need and that is not in the repo, such as `.env` → ask the user; never copy it on your own.
5. The issue lists *Assets* that are not committed on the branch yet → copy each from the main checkout to the same path in `<wt>` and commit them: `#<n>: Add assets`. A listed file that is missing → ask the user.
6. Feedback given (the argument after the number) → post it as an issue comment headed *Feedback from manual check*.
7. Set the status to In Progress.

## 3. Plan

The risk class starts from the issue's `risk/` label (CONVENTIONS.md, Risk).

**Continue**: a resume without feedback, on a branch that already has commits beyond `origin/<default>` (e.g. after a ❌ whose cause the user fixed by hand) → no planner and no new build. Post a short plan comment (continue: gate, final review, update), run the gate (step 4.2, with the worker fixing a red gate), then step 4.3, then the final review from R1 with the issue's current risk row, then steps 6–8.

**Fast path**: a fresh run (the branch has no commits beyond `origin/<default>`), the label is `risk/low`, and the issue has an *Approach* → no planner. Post the plan comment in the Kanban language, in this shape:

```
PLAN (fast path)
Risk: low (label)
Approach: from the issue
Tests: mapped by the worker, listed in the hand-over
```

Continue with step 4.

Otherwise, on a fresh run or a resume with feedback:

1. Spawn the planner in mode `work`, with the effort of the label's row in the risk table (Subagents); an issue without a `risk/` label → effort `high`.
2. It returns `QUESTIONS` → ask the user, wait, and continue the same planner with the answers.
3. Its risk is higher than the label, or the issue has no `risk/` label → set the planner's class as the label. The plan stands; the new class decides the reviews.
4. Post the plan as an issue comment in the Kanban language: risk class with reason (when it was raised: from what and why), *Tests*, *Deviations*, and *Approach* when the planner wrote one. The issue's own *Approach* is not repeated. On resume, the plan covers only the feedback.

## 4. Build

1. Spawn the worker with the plan (on the fast path: the issue's acceptance criteria, which the worker maps to tests itself) and the issue's *Approach*.
2. Run the **gate**: the helper's `gate`. `RED` → continue the worker with the helper's report, then gate again.
3. Gate green → fetch, then run the helper's `scope`; its report goes to every reviewer.

## 5. Review

Models, effort, and modes come from the risk table (Subagents).

1. **Intermediate review**, high risk only → the worker fixes its must-fix findings → gate.
2. **Final review R1**. Clean → step 6. Must-fix findings → the worker fixes them → gate.
3. **R2**: the same model and effort as R1 in mode `recheck`, given only the open findings. Clean → step 6.
4. Must-fix findings still open after R2 → **stop**: post exactly those findings (ID, `file:line`, problem) as one issue comment, leave the status at In Progress, lay them out for the user, and end with the verdict ❌ (step 8). A third review round does not exist.

Only must-fix findings go to the worker; collect the suggestions for the hand-over. A `CRITICAL` verdict means the change meets a high-risk criterion (CONVENTIONS.md, Risk) on a low- or normal-risk issue: set `risk/high`, post the reason as an issue comment, and start the final review again from R1 with the high row; the intermediate review is not repeated. After each review `git status` in `<wt>` must be clean; otherwise end with ❌ and report what the reviewer changed.

**Fable**: a final review on `fable` counts as unavailable when the call fails or the `REVIEWER:` line names another model. Retry a limit or overload error once; an access error not at all. Fable is tried anew on every run, so a plan upgrade takes effect at once. Unavailable → **reviewer-fallback**:

1. Reviewer on `opus`, effort `xhigh`, mode `full` with `checklist`: its report answers every item of the review checklist, each with `ok` or its finding IDs.
2. Check the report: an item without an answer → continue the same reviewer once with the missing items. Still unanswered → end with ❌ (step 8) and name the items.
3. Opus unavailable too → the same on `sonnet`, and the hand-over warns of reduced review depth.

R2 then runs on the fallback's model and effort in mode `recheck`.

## 6. Update and verify

1. Fetch, then merge the current default branch into the issue branch in `<wt>`: `git merge origin/<default>`. Already up to date → nothing to do. A conflict → `git merge --abort`, note the conflicting files, leave the status at In Progress, and go to step 8 with ❌; resolving it is the user's call.
2. Run the gate on the final commit, unless the last green gate already ran on that same commit. Green → step 7. Red after the worker's fixes, or a failure that already exists on the default branch → leave the status at In Progress and go to step 8 with ❌.

## 7. Hand over

1. Push the branch from `<wt>`: `git push -u origin <n>-<slug>`. No PR yet → create one: title = issue title, body = `Closes #<n>` plus one sentence, in the Kanban language.
2. **Checks**: wait for the PR's checks (adapter: PR checks), polling about every 30 seconds for at most 10 minutes. No check has shown up after the first minute → the repo has no CI for this PR. Note the result: passed, failed (with the failing check names), still pending after 10 minutes, or no CI. Read the PR's mergeability with the same call.
3. Post the hand-over comment on the issue, in the Kanban language. Its first line is the verdict from step 8, then:
   - *Changes*: what behaves differently now, key files, commits.
   - *Tests*: new or changed tests and what each one guards; suite and lint results with counts; the checks result.
   - *Manual check*: the worktree path `<wt>` to run the check in, then numbered steps covering every acceptance criterion (on resume: every feedback point), each with its expected result. Run every step you can run from the command line and quote its real output verbatim, untranslated; mark a step you could not run as *not run*, and say what the user has to look at for it, e.g. a visual check of the rendered page.
   - *Models*: the models that actually ran, with their effort, e.g. `plan opus/high · build sonnet · review <the reviewer's REVIEWER: model ID>/high`, or `fast path · build sonnet · review <model ID>/medium`; an escalation with its trigger, a raised risk class, a fallback with its reason, a reduced review depth with its warning.
   - *Notes*: the reviewers' suggestions and problems noticed outside the scope, as suggested follow-up issues. Omit when empty.
4. Verdict ✅ or ⏳ → set the status to Review. Verdict ❌ → leave it at In Progress.

## 8. Verdict

Decide exactly one verdict from what this run established, and write it in the Kanban language as the first line of the hand-over comment (or of the stop comment) and of your last message to the user:

| Verdict | When | Line |
|---|---|---|
| ✅ | Gate green on the final commit, no open must-fix finding, branch up to date with the default branch, PR open and mergeable, checks passed or no CI, and every manual check step that could run gave its expected result | `✅ Ready for /vibe-flow:done <n> after your manual check: <the steps marked not run, or "all steps passed">` |
| ⏳ | Everything as for ✅, except that checks are still pending after 10 minutes | `⏳ Almost ready: checks still running (<names>). /vibe-flow:done <n> checks them again before merging.` |
| ❌ | Anything else: a red gate, a role that failed again after its escalation, must-fix findings after R2, a fallback review with unanswered checklist items, a merge conflict, a failed check, a PR that is not mergeable, a manual check step with an unexpected result, or a `BLOCKED` that only the user can resolve | `❌ Not ready: <each reason in one line>. Next: <the concrete next move>` |

The next move for ❌ names what fits, e.g. `/vibe-flow:work <n> <feedback>` after the user decided on the findings, or resolving the conflict in `<wt>` and running `/vibe-flow:work <n>` again. After the verdict, tell the user the PR link and the worktree path, as far as they exist. Never run `/vibe-flow:done` yourself, whatever the verdict.
