# Forgejo adapter

Issues, comments, labels, milestones, PRs, and the status use the REST API. Forgejo has no API for project boards, so the status lives in `status/` labels (CONVENTIONS.md, Board). The board itself is an optional view, kept up in the user's Chrome through Claude in Chrome on the board URL from the CLAUDE.md `Board:` line, as far as that works.

## REST API

The token is read from the environment variable `FORGEJO_TOKEN`; never print it. `<host>`, `<owner>`, `<repo>` come from `git remote get-url origin`.

```bash
curl -sS -H "Authorization: token $FORGEJO_TOKEN" -H "Content-Type: application/json" \
  "https://<host>/api/v1/repos/<owner>/<repo>/<path>" [-X <METHOD> -d @<json file>]
```

| Operation | Request (`<path>` relative to the repo) |
|---|---|
| Check access | `GET https://<host>/api/v1/user` |
| Create issue | `POST issues` `{"title", "body", "labels": [<ids of the type, risk, and area labels>], "milestone": <id>}` → `number`, `html_url`. The status label comes with Set status. |
| Find duplicates | `GET issues?state=open&type=issues&q=<keywords>` |
| Read issue | `GET issues/<n>` and `GET issues/<n>/comments` |
| List open issues | `GET issues?state=open&type=issues&limit=50` |
| Comment | `POST issues/<n>/comments` `{"body"}` |
| List labels | `GET labels?limit=100` |
| Create label | `POST labels` `{"name", "color": "#rrggbb", "description"}` |
| Update label | `PATCH labels/<id>` `{"description"}` |
| Add labels | `POST issues/<n>/labels` `{"labels": [<label ids>]}` |
| Remove label | `DELETE issues/<n>/labels/<label id>` |
| Set risk label | Remove label for the current `risk/` label, then Add labels with the new one |
| List milestones | `GET milestones?state=open` |
| Create milestone | `POST milestones` `{"title"}` |
| Create repo | `POST https://<host>/api/v1/user/repos` `{"name", "private": true}`, then add the remote and push |
| Find PR of branch | `GET pulls?state=open`, match `head.ref` |
| Create PR | `POST pulls` `{"head": "<branch>", "base": "<default branch>", "title", "body"}` |
| Squash-merge | `POST pulls/<index>/merge` `{"Do": "squash", "MergeTitleField": "<commit message>", "delete_branch_after_merge": true}` |
| Close issue | `PATCH issues/<n>` `{"state": "closed"}` |

## Status (labels)

Label ids come from List labels. The issue's status is its one `status/` label; Done is the closed issue.

| Operation | Request |
|---|---|
| Set up board | The `status/` labels are created with the other labels in `/setup`. Then ask whether the user wants a board as a view; on yes, set it up in Chrome (Board view) and store its URL in `Board:`, otherwise store `none`. |
| Set status | Backlog, In Progress, Review: Remove label for each other `status/` label on the issue, then Add labels with the new one. Done: remove every `status/` label; the issue is closed by the merge or by Close issue. Then update the board view. |
| List issues in a status | `GET issues?state=open&type=issues&labels=status/<status>&limit=50`; Done: `GET issues?state=closed&type=issues&limit=50` |
| Remove from board | Remove every `status/` label, close the issue, then update the board view. |

## Board view (Chrome)

Only when `Board:` holds a URL. It mirrors the labels and never decides anything.

| Operation | In the web UI |
|---|---|
| Set up | Repo → Projects → New project, title = repo name, template "Basic Kanban". Rename and add columns until they are exactly the four statuses, in order; set Backlog as default. Store the board URL. |
| Update | For a new issue: issue page → sidebar "Projects" → select the board. For a status: board URL → drag card `#<n>` into the column. For a removal: issue page → sidebar "Projects" → clear the selection. |

When Claude in Chrome is not connected, or a board view step fails, tell the user the exact manual step (e.g. "move #12 to Review on the board") in one line and continue; the label already holds the status.
