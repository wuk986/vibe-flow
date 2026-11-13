---
name: review
description: Review one issue, a topic, or the whole project against the board - implementation vs. acceptance criteria, regressions, code quality, bottlenecks in code and board flow - and turn confirmed findings into Backlog issues.
disable-model-invocation: true
argument-hint: "[#n | topic]"
---

# review

Checks what the board says against what the code does: whether every issue in scope was implemented as its acceptance criteria say, whether anything regressed, how the code quality is, and where the code or the board flow has bottlenecks. A planner defines the review first; you confirm it. The result is a review issue with the report and, after your OK, one Backlog issue per confirmed finding. `/review` changes no code.

You are the **orchestrator**: you talk to the board and the user and steer the subagents.

## Subagents

Spawn each role as described in Subagents in CONVENTIONS.md, with the `model` and `effort` named here. This table is the only place that assigns models for `/review`.

| Role | Agent, mode | Model, effort | Used for |
|---|---|---|---|
| planner | `vibe-flow:planner`, mode `review` | `opus`, `high` | defining the review (step 4) |
| auditor | `vibe-flow:reviewer`, mode `audit` | `sonnet`, `high` | one review area each, in parallel (step 6) |
| verifier | `vibe-flow:reviewer`, mode `verify` | `opus`, `high`; fallback `fable`, `medium` | checking and merging the auditors' findings (step 7) |
| helper | `vibe-flow:helper`, tasks `gate` and `board` | `haiku` | test and lint run, board and git queries |

The verifier counts as unavailable when the call fails or its `REVIEWER:` line names another model; retry a limit or overload error once. Unavailable → the same task on the fallback, and the report names it. Every role gets the absolute path of the review worktree and works only there. A subagent's report is a claim; the gate verdict that counts is the helper's.

## 1. Scope

1. **Load context** as described in `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md`; `<plugin root>` there is `${CLAUDE_PLUGIN_ROOT}`.
2. The argument decides the scope:
   - `#<n>` → that issue, with the issues its `Depends on:` names.
   - Any other text → a topic, e.g. `login`, `area/ui-ux`, or `the export`. The planner maps it to issues and code in step 4.
   - None → the whole project.

## 2. Prepare

1. Fetch. The review worktree `<wt>` is `../<repo>.worktrees/review-<yyyymmdd-hhmm>`: `git worktree add --detach <wt> origin/<default>`. The review sees the default branch as it is on the remote; the main checkout stays as it is.
2. When the Test or Lint command needs installed dependencies, run the project's install step in `<wt>`. Local configuration the tests need and that is not in the repo, such as `.env` → ask the user; never copy it on your own.

## 3. Facts

Run both helper tasks in parallel:

- `gate` in `<wt>`: the regression baseline.
- `board` with the scope and the adapter path: the issues in scope with status, dates, and flow events, plus the open PRs, branches, and worktrees (agents/helper.md, board).

A red gate is a finding of its own; the review goes on.

## 4. Plan

1. Spawn the planner in mode `review` with the scope, both helper reports, and `<wt>`.
2. It returns `QUESTIONS` → ask the user, wait, and continue the same planner with the answers.
3. Show its `REVIEW PLAN` to the user: the areas, what each one covers, and what is out of scope. Wait for the OK or corrections; corrections go back to the same planner.

## 5. Review issue

Create the review issue (adapter: Create issue) in the Kanban language, labels `chore` and `risk/low`, without a status, so it never appears on the board:

- Title: `Review: <scope> (<yyyy-mm-dd>)`, the scope as `#<n>`, the topic, or `whole project`.
- Body: the confirmed review plan and the commit of `origin/<default>` it reviews.

## 6. Audit

Spawn one auditor per area of the plan, all in parallel. Each gets its area from the plan, the issues it covers (body, acceptance criteria, comments), the helper reports, and `<wt>`. Collect the reports.

## 7. Verify

Spawn the verifier with every auditor report, the plan, and the helper reports. It checks each finding against the code in `<wt>`, drops what does not hold, merges duplicates, and drafts a follow-up issue for each confirmed finding. When it reports `BLOCKED` or leaves a finding unchecked, continue it once with what is missing; still missing → keep the finding marked *unverified* in the report and propose no issue for it.

## 8. Report

Post the report as a comment on the review issue, in the Kanban language. Its first line is the result:

- `✅ No findings: <scope> matches the board.`
- `⚠️ <n> findings (<m> must-fix): <the areas they are in>.`

Then:

- *Board vs. code*: per issue in scope, whether every acceptance criterion is in the code and covered by a test; missing ones by name.
- *Regression*: the gate result with counts, and criteria of Done issues whose test is gone, skipped, or failing.
- *Code quality*: the findings, each with `file:line`.
- *Bottlenecks*: in the code (slow paths, expensive tests, coupling that slows changes), and in the board flow (time in In Progress and Review, feedback rounds, ❌ verdicts, open dependencies, stale branches, worktrees, and PRs).
- *Unverified*: findings the verifier could not check. Omit when empty.
- *Models*: the models that actually ran, with a fallback and its reason.

## 9. Follow-up issues

1. Show the verifier's drafted issues to the user, each with title, type, risk estimate with its reason, and the finding it comes from. The user picks, edits, or drops them; wait for the OK.
2. Create each confirmed one as `/vibe-flow:issue` step 6 does: labels type, area, and `risk/<class>`, status Backlog. Each body gets a line `Found in review #<review issue>`.
3. Post the list of created issues as a comment on the review issue, then close it (adapter: Close issue).

## 10. Clean up

`git worktree remove <wt>`; when the `../<repo>.worktrees` folder is empty afterwards, remove it too. Report the review issue URL, the result line, and the created issue numbers in a few lines.
