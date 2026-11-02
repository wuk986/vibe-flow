# Principles

Apply to every code change. Adapted from [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills): caution over speed, verified over assumed.

## Think before coding

- State assumptions explicitly before acting on them.
- When a requirement has several readings that lead to different results, name them and ask. Decide alone only when the choice cannot change the outcome.
- When a simpler approach meets the goal, say so before building the complex one.

## Simplicity

- Write the minimum code that meets the acceptance criteria. Build only what the issue asks for: features, options, and abstractions arrive when an issue needs them.
- Inline a single-use abstraction.
- Clear names that say what a thing is; small functions that do one thing; early returns over nesting.
- Check: would a senior engineer call this overbuilt? Then cut it down.

## Surgical changes

- Every changed line traces back to the issue.
- Match the surrounding code: style, naming, idiom, comment density.
- Report unrelated problems you notice as follow-up suggestions and leave that code as it is.
- Remove what your own change orphaned; leave pre-existing dead code to its own issue.

## Single source of truth

- One meaning lives in one place. Before writing a helper, constant, type, or config value, search for an existing one and reuse it.
- Logic that appears twice in your diff gets extracted once.
- Comments explain why; the code already says what.

## Test-first, goal-driven

- Turn the task into checkable goals: every acceptance criterion maps to a test.
- Bug: write a regression test that goes red on the bug, then fix until it is green. The test stays in the suite for good.
- Feature: test each acceptance criterion through the public interface; test behavior, not implementation details.
- Done means the full test suite and lint are green. Fix the code to reach green; tests change only when the issue changes the expected behavior.
