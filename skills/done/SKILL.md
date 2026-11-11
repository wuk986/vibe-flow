---
name: done
description: Finish an issue after the user's manual check passed - squash-merge the PR, close the issue, move it to Done.
disable-model-invocation: true
argument-hint: "[#n]"
---

# done

The user runs this after checking the work by hand; running it is their approval to merge.

## Steps

1. **Load context** as described in `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md`; `<plugin root>` there is `${CLAUDE_PLUGIN_ROOT}`.
2. **Pick the issue**: the number given, else the one from the current branch name `<n>-<slug>`, else list the issues in Review and ask.
3. **Check**: the issue is in Review and its branch has an open PR that is mergeable with no failing checks. Anything else → stop and report what is off.
4. **Merge**: squash-merge the PR and delete the remote branch. Commit message: `#<n>: <issue title>`, translated into the Commit language when it differs.
5. **Close**: tick the acceptance criteria in the issue body (every `- [ ]` becomes `- [x]`; a criterion moved to another issue stays unticked as a reference to it), post a closing comment in the Kanban language (manual check passed, merged as `<short sha>`), close the issue if the merge did not, and set the status to Done.
6. **Local**: check out the default branch, `git pull --prune`, delete the local issue branch. When `graphify-out/` exists, run `graphify update .`.
7. **Report** the merge commit and the issue URL in one or two lines.
