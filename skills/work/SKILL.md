---
name: work
description: Work a kanban issue end to end - Opus plans, Sonnet/Haiku builds test-first, risk-based review (Sonnet/Opus/Fable), green gate, PR, move to Review.
disable-model-invocation: true
argument-hint: "[#n] [feedback from manual check]"
---

# work

Takes one issue from Backlog (or back from Review with feedback) to Review: gate green, PR open, everything documented on the issue. You are the **orchestrator**: you talk to the board and the user and steer the subagents; planning, building, and reviewing run in subagents on the model this skill assigns. Work autonomously; stop for the user only where a step says so.

## Subagents

Spawn each role as described in Subagents in CONVENTIONS.md, with the `model` named here.

| Role | Model |
|---|---|
| planner | `opus` |
| worker | from the plan: `sonnet` or `haiku` |
| reviewer | from the review table in step 5 |
| helper | `haiku` |

A subagent's report is a claim. The gate verdict that counts is the helper's.

**Escalation**: once per step, run the worker or reviewer one level higher (haiku → sonnet → opus) when the gate is red twice for the same `Reason`, when the same finding ID appears in two reviews in a row, or when it reports `BLOCKED`. A `BLOCKED` that needs information only the user has → ask the user instead. Fable is never an escalation level.

## 1. Pick the issue

1. **Load context** as described in `~/.claude/vibe-flow/CONVENTIONS.md`.
2. No issue number given → list the Backlog issues (number, title, type) and ask which one.
3. Read the issue: body, labels, every comment. A closed issue or one in Done → stop and say so.
4. Its `Depends on: #<m>` names an open issue → stop and say which one.

## 2. Prepare

1. `git status` shows uncommitted changes other than the issue's *Assets* → stop, show them, and ask the user how to proceed. Their changes are theirs to stash, commit, or discard.
2. Other issues in In Progress → mention them in one line and continue.
3. Branch `<n>-<slug>` exists locally or on the remote → **resume**: check it out and pull. Otherwise create it from the freshly pulled default branch.
4. The issue lists *Assets* that are not committed yet → commit them on the branch: `#<n>: Add assets`. A listed file that is missing → stop and ask the user.
5. Feedback given (the argument after the number) → post it as an issue comment headed *Feedback from manual check*.
6. Set the status to In Progress.

## 3. Plan

1. Spawn the planner in mode `work`.
2. It returns `QUESTIONS` → ask the user, wait, and continue the same planner with the answers.
3. Post the plan as an issue comment in the Kanban language: risk class with reason, worker model, *Tests*, *Deviations*, and *Approach* when the planner wrote one. The issue's own *Approach* is not repeated. On resume, the plan covers only the feedback.

## 4. Build

1. Spawn the worker with the plan and the issue's *Approach*.
2. Run the **gate**: the helper's `gate`. `RED` → continue the worker with the helper's report, then gate again.
3. Gate green → run the helper's `scope`; its report goes to every reviewer.

## 5. Review

| Risk | Intermediate review | Final review R1 and R2 |
|---|---|---|
| low | none | `sonnet`, mode `light` |
| normal | `sonnet`, mode `light` | `opus`, mode `full` |
| high | `opus`, mode `light` | `fable`, mode `full` |

1. **Intermediate review** → the worker fixes its must-fix findings → gate.
2. **Final review R1** → the worker fixes its must-fix findings → gate.
3. **R2**: the same model as R1 in mode `recheck`, given only the open findings. Clean → step 6.
4. Must-fix findings still open after R2 → **stop**: post exactly those findings (ID, `file:line`, problem) as one issue comment, leave the status at In Progress, and lay them out for the user. A third review round does not exist.

Only must-fix findings go to the worker; collect the suggestions for the hand-over. A `CRITICAL` verdict on a low-risk issue raises it to normal; continue with that row. After each review `git status` must be clean; otherwise stop and report what the reviewer changed.

**Fable**: a final review on `fable` counts as unavailable when the call fails or the `REVIEWER:` line names another model. Retry a limit or overload error once; an access error not at all. Fable is tried anew on every run, so a plan upgrade takes effect at once. Unavailable →

1. Reviewer on `opus` with effort `high`, mode `full`, and in parallel an independent reviewer on `sonnet`, mode `focus`.
2. Merge both finding lists and check each finding against the code yourself; drop the ones that do not hold before the worker sees them.
3. Opus unavailable too → reviewer on `sonnet`, mode `full`, and the hand-over warns of reduced review depth.

## 6. Verify

Run the gate once more on the final commit. Green → step 7. Red after the worker's fixes, or a failure that already exists on the default branch → stop, report it to the user, and leave the status at In Progress.

## 7. Hand over

1. Push the branch. No PR yet → create one: title = issue title, body = `Closes #<n>` plus one sentence, in the Kanban language.
2. Post the hand-over comment on the issue, in the Kanban language:
   - *Changes*: what behaves differently now, key files, commits.
   - *Tests*: new or changed tests and what each one guards; suite and lint results with counts.
   - *Manual check*: numbered steps covering every acceptance criterion (on resume: every feedback point), each with its expected result. Run every step you can run from the command line and quote its real output verbatim, untranslated; mark a step you could not run as *not run*.
   - *Models*: the models that actually ran, e.g. `plan opus · build sonnet · review claude-fable-5-1`; a fallback with its reason, a reduced review depth with its warning.
   - *Notes*: the reviewers' suggestions and problems noticed outside the scope, as suggested follow-up issues. Omit when empty.
3. Set the status to Review.
4. Tell the user: the PR link, the manual check steps, and the next move: `/done <n>` when the check passes, `/work <n> <feedback>` when it does not.
