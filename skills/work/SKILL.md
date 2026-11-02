---
name: work
description: Work a kanban issue end to end - branch, test-first implementation, self-review, green suite, PR, move to Review.
disable-model-invocation: true
argument-hint: "[#n] [feedback from manual check]"
---

# work

Takes one issue from Backlog (or back from Review with feedback) to Review: tests green, PR open, everything documented on the issue. Work autonomously; stop for the user only where a step says so.

Read `~/.claude/vibe-flow/PRINCIPLES.md`; it governs every change below.

## 1. Pick the issue

1. **Load context** as described in `~/.claude/vibe-flow/CONVENTIONS.md`.
2. No issue number given → list the Backlog issues (number, title, type) and ask which one.
3. Read the issue: body, labels, every comment. A closed issue or one in Done → stop and say so.

## 2. Prepare

1. `git status` shows uncommitted changes → stop, show them, and ask the user how to proceed. Their changes are theirs to stash, commit, or discard.
2. Other issues in In Progress → mention them in one line and continue.
3. Branch `<n>-<slug>` exists locally or on the remote → **resume**: check it out and pull. Otherwise create it from the freshly pulled default branch.
4. Feedback given (the argument after the number) → post it as an issue comment headed *Feedback from manual check*.
5. Set the status to In Progress.

## 3. Plan

1. Map every acceptance criterion (on resume: every feedback point) to the test that proves it and the change that satisfies it.
2. An ambiguity that would change the result → ask the user and wait. Everything else: decide, and record the decision as an assumption.
3. Post the plan as an issue comment with three parts: *Assumptions*, *Approach* (short steps, each with its check), *Affected areas* (files or modules). On resume, the plan covers only the feedback.

## 4. Implement test-first

By the issue's type label:

- `bug`: write a regression test that reproduces the bug and watch it go **red** for the right reason. Then fix until it is green.
- `feature`: write the tests for the acceptance criteria through the public interface and watch them go red. Then implement until they are green.
- `chore`: run the full suite first to record the baseline. The existing suite is the guard; the behavior must stay identical.

Commit in small steps: `#<n>: <imperative summary>` in the Commit language.

## 5. Self-review

Read the whole diff against the default branch (`git diff <default>...HEAD`) and check it against every section of PRINCIPLES.md: lines that do not trace back to the issue, duplicates of code that already exists, speculative code, leftovers your change orphaned, style that differs from its surroundings. Fix and commit what you find. Done when every section is checked and nothing is open.

## 6. Verify

Run the Test and the Lint command from the CLAUDE.md section. Both green → continue. Red → fix and run again. A failure you cannot resolve, or one that already fails on the default branch → stop, report it to the user, and leave the status at In Progress.

## 7. Hand over

1. Push the branch. No PR yet → create one: title = issue title, body = `Closes #<n>` plus one sentence, in the Kanban language.
2. Post the hand-over comment on the issue, in the Kanban language:
   - *Changes*: what behaves differently now, key files, commits.
   - *Tests*: new or changed tests and what each one guards; suite and lint results with counts.
   - *Manual check*: numbered steps covering every acceptance criterion (on resume: every feedback point), each with its expected result.
   - *Notes*: assumptions made and problems noticed outside the scope, as suggested follow-up issues. Omit when empty.
3. Set the status to Review.
4. Tell the user: the PR link, the manual check steps, and the next move: `/done <n>` when the check passes, `/work <n> <feedback>` when it does not.
