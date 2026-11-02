# GitHub adapter

Everything runs through `gh` inside the project checkout. It needs the `repo` and `project` scopes; when a call fails on scopes, have the user run `gh auth refresh -s project`.

`<P>` is the project number from the CLAUDE.md `Board:` line. `board` stands for `bash ~/.claude/vibe-flow/forges/github-board.sh`. In `gh api` paths, gh fills in `{owner}` and `{repo}` itself.

| Operation | Command |
|---|---|
| Set up board | `board init "<repo name>"` → prints `<P>`; safe to re-run |
| Set status | `board status <P> <n> "<Status>"` (adds the issue to the board if needed) |
| List issues in a status | `board list <P> "<Status>"` |
| Create issue | `gh issue create --title "<title>" --body-file <file> --label <type> [--label area/<x>] [--milestone "<name>"]` → prints the URL |
| Find duplicates | `gh issue list --state open --search "<keywords>"` |
| Read issue | `gh issue view <n> --comments` (`--json state,labels,title` for fields) |
| Comment | `gh issue comment <n> --body-file <file>` |
| List labels | `gh label list --limit 200` |
| Create label | `gh label create "<name>" --color <hex> --description "<text>" --force` |
| List milestones | `gh api "repos/{owner}/{repo}/milestones?state=open" -q '.[].title'` |
| Create milestone | `gh api repos/{owner}/{repo}/milestones -f title="<name>"` |
| Create repo | `gh repo create <name> --private --source . --push` |
| Find PR of branch | `gh pr view <branch> --json number,url,state,mergeable,statusCheckRollup` |
| Create PR | `gh pr create --head <branch> --title "<title>" --body-file <file>` |
| Squash-merge | `gh pr merge <pr> --squash --delete-branch --subject "<commit message>"` |
| Close issue | `gh issue close <n>` |
