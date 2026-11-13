# GitHub adapter

Everything runs through `gh` inside the project checkout. It needs the `repo` and `project` scopes; when a call fails on scopes, have the user run `gh auth refresh -s project`.

`<P>` is the project number from the CLAUDE.md `Board:` line. `board` stands for `bash "<plugin root>/forges/github-board.sh"`. In `gh api` paths, gh fills in `{owner}` and `{repo}` itself.

| Operation | Command |
|---|---|
| Set up board | `board init "<repo name>"` → prints `<P>`; safe to re-run. It stops instead of resetting cards when a board with cards has other Status options; then tell the user what it printed. |
| Set status | `board status <P> <n> "<Status>"` (adds the issue to the board if needed) |
| List issues in a status | `board list <P> "<Status>"` |
| Remove from board | `board remove <P> <n>` (the issue itself stays) |
| Create issue | `gh issue create --title "<title>" --body-file <file> --label <type> --label risk/<class> [--label area/<x>] [--milestone "<name>"]` → prints the URL. The issue is not on the board yet; Set status puts it there. |
| Find duplicates | `gh issue list --state open --search "<keywords>"` |
| Read issue | `gh issue view <n> --comments` (`--json state,labels,title` for fields) |
| Comment | `gh issue comment <n> --body-file <file>` |
| Edit issue body | `gh issue edit <n> --body-file <file>` |
| List labels | `gh label list --limit 200` |
| Set risk label | `gh issue edit <n> --remove-label risk/<old> --add-label risk/<new>` (without `--remove-label` when the issue has none) |
| Create label | `gh label create "<name>" --color <hex> --description "<text>" --force`; on an existing label this updates color and description |
| List milestones | `gh api "repos/{owner}/{repo}/milestones?state=open" -q '.[].title'` |
| Create milestone | `gh api repos/{owner}/{repo}/milestones -f title="<name>"` |
| Create repo | `gh repo create <name> --private --source . --push` |
| Find PR of branch | `gh pr view <branch> --json number,url,state,mergeable,statusCheckRollup` |
| PR checks | `gh pr checks <pr> --json name,bucket`: each check's `bucket` is `pass`, `fail`, `pending`, `skipping`, or `cancel` (`fail` and `cancel` count as failed). The error "no checks reported" means no CI. Mergeability: `gh pr view <pr> --json mergeable` → `MERGEABLE`, `CONFLICTING`, or `UNKNOWN` (GitHub is still computing it: ask again on the next poll). |
| Create PR | `gh pr create --head <branch> --title "<title>" --body-file <file>` |
| Squash-merge | `gh pr merge <pr> --squash --subject "<commit message>"`, then delete the remote branch: `git push origin --delete <branch>` (an error that the ref does not exist means the repo already deleted it). No `--delete-branch`: the local branch is still checked out in the issue's worktree, and `/done` deletes it itself. |
| Close issue | `gh issue close <n>` |
