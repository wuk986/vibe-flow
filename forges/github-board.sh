#!/usr/bin/env bash
# GitHub Projects v2 board operations for vibe-flow.
#   github-board.sh init <title>                  find or create the board, link the repo, print its number
#   github-board.sh status <project> <issue> <status>  add the issue to the board and set its column
#   github-board.sh list <project> <status>       print "<number>\t<title>" of issues in that column
#   github-board.sh remove <project> <issue>      take the issue's card off the board
# Runs inside the project's git checkout; needs gh with the "project" scope.
set -euo pipefail

STATUSES='Backlog,In Progress,Review,Done'

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
owner=${repo%%/*}

status_field() { # <project> <jq suffix>
  gh project field-list "$1" --owner "$owner" --format json -q ".fields[] | select(.name==\"Status\") $2"
}

case "${1:-}" in
  init)
    title=$2
    number=$(gh project list --owner "$owner" --limit 500 --format json -q ".projects[] | select(.title==\"$title\") | .number" | head -n1)
    if [ -z "$number" ]; then
      number=$(gh project create --owner "$owner" --title "$title" --format json -q .number)
    fi
    gh project link "$number" --owner "$owner" --repo "$repo" >/dev/null  # no-op when already linked
    current=$(status_field "$number" '| [.options[].name] | join(",")')
    if [ "$current" != "$STATUSES" ]; then
      # Replacing the options resets every card's status, so only do it on a board without cards.
      items=$(gh project item-list "$number" --owner "$owner" --limit 1 --format json -q '.items | length')
      if [ "$items" != "0" ]; then
        echo "Board $number has cards but its Status options are \"$current\", not \"$STATUSES\"." >&2
        echo "Rename or add the options by hand in the board settings, then run init again." >&2
        exit 1
      fi
      gh api graphql -f fieldId="$(status_field "$number" '| .id')" -f query='
        mutation($fieldId: ID!) {
          updateProjectV2Field(input: {fieldId: $fieldId, singleSelectOptions: [
            {name: "Backlog", color: GRAY, description: "Described, not started"},
            {name: "In Progress", color: YELLOW, description: "Being worked on"},
            {name: "Review", color: BLUE, description: "Waiting for manual check"},
            {name: "Done", color: GREEN, description: "Checked, merged, closed"}
          ]}) { projectV2Field { ... on ProjectV2SingleSelectField { id } } }
        }' >/dev/null
    fi
    echo "$number"
    ;;
  status)
    project=$2 issue=$3 status=$4
    project_id=$(gh project view "$project" --owner "$owner" --format json -q .id)
    url=$(gh issue view "$issue" --json url -q .url)
    # A freshly created issue can hit a transient "temporary conflict"; retry briefly.
    for attempt in 1 2 3; do
      item_id=$(gh project item-add "$project" --owner "$owner" --url "$url" --format json -q .id) && break
      [ "$attempt" = 3 ] && exit 1
      sleep 2
    done
    field_id=$(status_field "$project" '| .id')
    option_id=$(status_field "$project" "| .options[] | select(.name==\"$status\") | .id")
    if [ -z "$option_id" ]; then
      echo "Status \"$status\" not found on board $project (expected: $STATUSES)" >&2
      exit 1
    fi
    gh project item-edit --project-id "$project_id" --id "$item_id" --field-id "$field_id" --single-select-option-id "$option_id" >/dev/null
    echo "#$issue -> $status"
    ;;
  list)
    project=$2 status=$3
    gh project item-list "$project" --owner "$owner" --format json --limit 500 \
      -q ".items[] | select(.status==\"$status\" and .content.type==\"Issue\") | \"\(.content.number)\t\(.content.title)\""
    ;;
  remove)
    project=$2 issue=$3
    url=$(gh issue view "$issue" --json url -q .url)
    item_id=$(gh project item-add "$project" --owner "$owner" --url "$url" --format json -q .id)
    gh project item-delete "$project" --owner "$owner" --id "$item_id" >/dev/null
    echo "#$issue removed from board"
    ;;
  *)
    sed -n '2,7p' "$0" >&2
    exit 2
    ;;
esac
