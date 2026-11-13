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
| helper | `vibe-flow:helper`, tasks `gate` and `board` | `haiku`, default effort | test and lint run, board and git queries |

The verifier counts as unavailable when the call fails or its `REVIEWER:` line names another model; retry a limit or overload error once. Unavailable → the same task on the fallback, and the report names it. Every role gets the absolute paths of the review worktrees (step 2) and works only in them; copies, exports, and notes go into `<tmp>`, never anywhere else. A subagent's report is a claim; the gate verdict that counts is the helper's.

## 1. Scope

1. **Load context** as described in `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md`; `<plugin root>` there is `${CLAUDE_PLUGIN_ROOT}`.
2. The argument decides the scope:
   - `#<n>` → that issue, with the issues its `Depends on:` names.
   - Any other text → a topic, e.g. `login`, `area/ui-ux`, or `the export`. The planner maps it to issues and code in step 4.
   - None → the whole project.
3. **Earlier reviews**: look for open issues whose title starts with `Review:` (adapter: List issues). Such an issue waits for the user's OK on its follow-ups. Show it and ask: finish that review first (stop here), or go on. Going on → its report and drafted issues are *known*: every role gets them, and a finding they already contain is neither proposed nor counted again.

## 2. Prepare

1. Fetch. The review worktree `<wt>` is `../<repo>.worktrees/review-<yyyymmdd-hhmm>`, in local time: `git worktree add --detach <wt> origin/<default>`. The review sees the default branch as it is on the remote; the main checkout stays as it is.
2. The folder `<tmp>` is `<wt>-tmp`, beside `<wt>`: it holds the issue texts of step 3 and whatever a role exports or copies. Nothing goes into `<wt>` itself.
3. An issue in Review has its code only on its PR branch. For each one the scope covers, add `<wt>-<n>`: `git worktree add --detach <wt>-<n> origin/<branch>`. Its criteria are checked there; the default branch is checked in `<wt>`.
4. When the Test or Lint command needs installed dependencies, run the project's install step in each worktree whose tests run. Local configuration the tests need and that is not in the repo, such as `.env` → ask the user; never copy it on your own.

## 3. Facts

Run both helper tasks in parallel:

- `gate` in `<wt>`: the regression baseline.
- `board` with the scope, the adapter path, and `<plugin root>`, so the helper can run the adapter's commands, e.g. the GitHub board script with the project number from the `Board:` line: the issues in scope with status, dates, and flow events, plus the open PRs, branches, and worktrees (agents/helper.md, board).

When the board report shows issues in Review that step 2.3 has no worktree for yet, add them now.

A red gate is a finding of its own; the review goes on.

Then read every issue in scope yourself (adapter: Read issue: body and comments) and save the texts in `<tmp>`; the planner, the auditors, and the verifier get them from there.

## 4. Plan

1. Spawn the planner in mode `review` with the scope, both helper reports, the issue texts, the known findings of step 1.3, `<wt>`, and the Review worktrees `<wt>-<n>`.
2. It returns `QUESTIONS` → ask the user, wait, and continue the same planner with the answers.
3. Show its `REVIEW PLAN` to the user: the areas, what each one covers, and what is out of scope. Wait for the OK or corrections; corrections go back to the same planner.

## 5. Review issue

Create the review issue (adapter: Create issue) in the Kanban language, labels `chore` and `risk/low`, without a status, so it never appears on the board:

- Title: `Review: <scope> (<yyyy-mm-dd>)`. `Review:` and the date stay as they are, so review issues are easy to find; the scope is `#<n>`, the topic, or the words for *whole project* in the Kanban language.
- Body: the confirmed review plan, the commit of `origin/<default>` it reviews, and the path of `<wt>`, so a leftover worktree can be traced to its review.

## 6. Audit

Spawn one auditor per area of the plan, all in parallel. Each gets its area, the names of all other areas, the texts of the issues it covers (from `<tmp>`), the known findings, the helper reports, `<wt>`, and the Review worktrees its issues need. Collect the reports.

## 7. Verify

Spawn the verifier with every auditor report, the plan, the helper reports, the known findings, and the worktrees. It checks each finding against the code, drops what does not hold, merges duplicates, and sorts each confirmed finding into one of four kinds (agents/reviewer.md, verify):

- **issue**: a change to the project's code, tests, or docs → a drafted follow-up issue.
- **recommendation**: a board action that needs no code, e.g. a missing `risk/` label, a stale branch, or a pending manual check; and any finding on an issue in Review, which becomes feedback for it: `/vibe-flow:work <n> <feedback>`. No new issue.
- **outside**: a point about vibe-flow or another tool, not about the project. No issue in the project.
- **known**: already in an earlier open review's report or drafts (step 1.3), or something that only extends one of its drafts. The report names where; no new issue.

When it reports `BLOCKED` or leaves a finding unchecked, continue it once with what is missing; still missing → keep the finding marked *unverified* in the report and propose no issue for it.

## 8. Report

Post the report as a comment on the review issue, in the Kanban language. Its first line is the result:

- `✅ No findings: <scope> matches the board.`
- `⚠️ <n> findings (<m> must-fix): <the areas they are in>.`

Write the line in the Kanban language; only the emoji and the numbers are fixed. `<n>` counts every confirmed finding of the kinds issue and recommendation; `<m>` the must-fix ones among them. Known findings do not count. `must-fix` may be translated like the rest.

Then:

- *Board vs. code*: per issue in scope, whether every acceptance criterion is in the code and covered by a test; a criterion that has no test by design, e.g. one on docs, counts as met when it was checked by inspection or a command, and the report says which. Missing ones by name.
- *Regression*: the gate result with counts, and criteria of Done issues whose test is gone, skipped, or failing.
- *Code quality*: the findings, each with `file:line`.
- *Bottlenecks*: in the code (slow paths, expensive tests, coupling that slows changes), and in the board flow (time in In Progress and Review, feedback rounds, ❌ verdicts, open dependencies, stale branches, worktrees, and PRs).
- *Recommendations*: the board actions, and the feedback per issue in Review with the `/vibe-flow:work <n> <feedback>` call. Omit when empty.
- *Unverified*: findings the verifier could not check. Omit when empty.
- *Outside*: points about vibe-flow or other tools, for the user. Omit when empty.
- *Known*: findings already in an earlier open review, each with that review issue and its draft. Omit when empty.
- *Models*: the models that actually ran, with a fallback and its reason.

## 9. Follow-up issues

1. Show the verifier's drafted issues to the user, each with title, type, risk estimate with its reason, and the finding it comes from. Show the recommendations next to them; carrying them out is the user's call, `/review` does not. The user picks, edits, or drops the issues; wait for the OK.
2. Create each confirmed one with the body of `/vibe-flow:issue` step 4 (Goal, Acceptance criteria, Out of scope, Approach, Risks, and `Depends on:` when the draft names one), its headings in the Kanban language as the project's existing issues write them, the way its step 6 does: labels type, area, and `risk/<class>`, status Backlog. Each body gets a line `Found in review #<review issue>`.
3. Post the list of created issues as a comment on the review issue, then close it (adapter: Close issue).

## 10. Clean up

`git worktree remove` for `<wt>` and every `<wt>-<n>`, then delete `<tmp>`. Ignored files such as a `.venv` or caches do not block the remove. When it refuses because of other changes, a role broke the rule that it changes no files: show `git status` of that worktree and ask before `--force`. A review worktree of an earlier run is left alone: the board report names it, and the report recommends finishing or removing it. When the `../<repo>.worktrees` folder is empty afterwards, remove it too. Report the review issue URL, the result line, and the created issue numbers in a few lines.
