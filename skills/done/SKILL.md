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
2. **Pick the issue**: the number given, else the one from the current branch name `<n>-<slug>` (when run inside the issue's worktree), else list the issues in Review and ask. Run every following step from the main checkout, the one `git worktree list` names first.
3. **Check**: the issue is in Review and its branch has an open PR that is mergeable with no failing checks. Anything else → stop and report what is off.
4. **Merge**: squash-merge the PR and delete the remote branch. Commit message: `#<n>: <issue title>`, translated into the Commit language when it differs.
5. **Close**: tick the acceptance criteria in the issue body (every `- [ ]` becomes `- [x]`; a criterion moved to another issue stays unticked as a reference to it), post a closing comment in the Kanban language (manual check passed, merged as `<short sha>`), close the issue if the merge did not, and set the status to Done.
6. **Local**:
   1. Remove the issue's worktree `<wt>` (CONVENTIONS.md, Git): `git worktree remove <wt>`. It refuses when `<wt>` has uncommitted changes → stop here, show them, and let the user decide; the merge and the board are already done. When the `../<repo>.worktrees` folder is empty afterwards, remove it too. No worktree, because the branch is checked out in the main checkout as vibe-flow 1.x did it → check out the default branch there instead.
   2. `git fetch --prune`, then delete the local issue branch with `git branch -D <n>-<slug>`; after a squash merge git does not see it as merged.
   3. The main checkout is on the default branch → `git pull --ff-only`. An *Asset* of the issue that sits there untracked would block the pull: when it is byte-identical to the merged file, list it and ask the user to let you remove it, since the pull brings it back unchanged; when it differs, stop and show the difference. The main checkout is on another branch → leave it and say that the default branch was not pulled.
   4. When `graphify-out/` exists, run `graphify update .`.
7. **Report** the merge commit and the issue URL in one or two lines.
