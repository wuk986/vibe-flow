# Gitea adapter

Gitea and Forgejo share the REST API for issues, comments, labels, milestones, and PRs, so those operations come from the Forgejo adapter: read `forgejo.md` in this folder and use its REST API section, with the token from `GITEA_TOKEN`.

The status depends on the CLAUDE.md `Board:` line, which `/setup` fills from the Gitea version:

- **A project id** (Gitea 28.0.0 or later, which has the project board API): the status lives only in the board column of a project in the repo, like on GitHub. Use the Board section below. Done is the Done column plus the closed issue.
- **A board URL or `none`** (older Gitea): use the Status (labels) and Board view sections of `forgejo.md`.

## Board (API)

`<P>` is the project id from `Board:`. Project paths are relative to the repo, like the REST API in `forgejo.md`. `<issue id>` is the issue's global `id` from `GET issues/<n>`, not its number `<n>`; the project endpoints take only the global id.

| Operation | Request |
|---|---|
| Set up board | Find a project titled with the repo name: `GET projects?state=open`. None → `POST projects` `{"title": "<repo name>", "template_type": "none"}` → `id`. Then `GET projects/<P>/columns`: create each missing status with `POST projects/<P>/columns` `{"title": "<Status>"}`, delete columns that are no status and hold no issue (`DELETE projects/<P>/columns/<column id>`; one that holds issues → ask the user), put them in order with `POST projects/<P>/columns/move` `{"column_ids": [<Backlog>, <In Progress>, <Review>, <Done>]}`, and make Backlog the default: `POST projects/<P>/columns/<Backlog id>/default`. Store `<P>` in `Board:`. Safe to re-run. |
| Column ids | `GET projects/<P>/columns` → `id` and `title` of each column; match the title to the status. |
| Set status | Find the issue's current column: `GET projects/<P>/columns/<column id>/issues?limit=50` for each of the four columns, matching `number`. On the board → `POST projects/<P>/issues/<issue id>/move` `{"column_id": <target column id>}`. Not on the board yet → `POST projects/<P>/columns/<target column id>/issues/<issue id>`. |
| List issues in a status | `GET projects/<P>/columns/<column id>/issues?limit=50` → each issue's `number` and `title`. |
| Remove from board | `DELETE projects/<P>/columns/<column id>/issues/<issue id>` for the column the issue is in; the issue itself stays. |

A `404` on a project path means the project or column no longer exists, or the instance is older than 28.0.0 → stop and tell the user to re-run `/vibe-flow:setup`.
