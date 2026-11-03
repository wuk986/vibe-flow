# Forgejo adapter

Issues, comments, labels, milestones, and PRs use the REST API. The project board has no API, so board operations run in the user's Chrome through Claude in Chrome, on the board URL from the CLAUDE.md `Board:` line.

## REST API

The token is read from the environment variable `FORGEJO_TOKEN`; never print it. `<host>`, `<owner>`, `<repo>` come from `git remote get-url origin`.

```bash
curl -sS -H "Authorization: token $FORGEJO_TOKEN" -H "Content-Type: application/json" \
  "https://<host>/api/v1/repos/<owner>/<repo>/<path>" [-X <METHOD> -d @<json file>]
```

| Operation | Request (`<path>` relative to the repo) |
|---|---|
| Check access | `GET https://<host>/api/v1/user` |
| Create issue | `POST issues` `{"title", "body", "labels": [<label ids>], "milestone": <id>}` → `number`, `html_url` |
| Find duplicates | `GET issues?state=open&type=issues&q=<keywords>` |
| Read issue | `GET issues/<n>` and `GET issues/<n>/comments` |
| List open issues | `GET issues?state=open&type=issues&limit=50` |
| Comment | `POST issues/<n>/comments` `{"body"}` |
| List labels | `GET labels?limit=100` |
| Create label | `POST labels` `{"name", "color": "#rrggbb", "description"}` |
| List milestones | `GET milestones?state=open` |
| Create milestone | `POST milestones` `{"title"}` |
| Create repo | `POST https://<host>/api/v1/user/repos` `{"name", "private": true}`, then add the remote and push |
| Find PR of branch | `GET pulls?state=open`, match `head.ref` |
| Create PR | `POST pulls` `{"head": "<branch>", "base": "<default branch>", "title", "body"}` |
| Squash-merge | `POST pulls/<index>/merge` `{"Do": "squash", "MergeTitleField": "<commit message>", "delete_branch_after_merge": true}` |
| Close issue | `PATCH issues/<n>` `{"state": "closed"}` |

## Board (Chrome)

| Operation | In the web UI |
|---|---|
| Set up board | Repo → Projects → New project, title = repo name, template "Basic Kanban". Rename and add columns until they are exactly the four statuses, in order; set Backlog as default. Store the board URL. |
| Add issue | Issue page → sidebar "Projects" → select the board. |
| Set status | Board URL → drag card `#<n>` into the column. |
| List issues in a status | Read the column from the board page. |
| Remove from board | Issue page → sidebar "Projects" → clear the selection. |

When Claude in Chrome is not connected, or a board step fails, tell the user the exact manual step (e.g. "move #12 to Review") and continue with the rest of the skill.
