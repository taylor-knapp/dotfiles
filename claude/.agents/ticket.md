# Ticket System

This project uses a CLI ticket system called `ticket` (alias: `tk`). Tickets are stored as markdown files with YAML frontmatter in `.tickets/`. Run `tk help` for the full manual.

Source: https://github.com/wedow/ticket

## Creating Tickets

```bash
tk create "Title" [options]
```

| Flag                | Description                                      |
| ------------------- | ------------------------------------------------ |
| `-d, --description` | Description                                      |
| `--design`          | Design/tactical notes                            |
| `--acceptance`      | Acceptance criteria                              |
| `-t, --type`        | `bug|feature|task|epic|chore` (default: task)    |
| `-p, --priority`    | 0-4, 0=critical (default: 2)                     |
| `-a, --assignee`    | Assigned person (defaults to git user.name)      |
| `--external-ref`    | External reference (e.g., `gh-123`, `JIRA-456`)  |
| `--parent`          | Parent ticket ID (for epic-to-task hierarchy)    |
| `--tags`            | Comma-separated tags (e.g., `--tags ui,backend`) |

## Status Workflow

```
open --> in_progress --> closed
```

| Command                   | Description            |
| ------------------------- | ---------------------- |
| `tk start <id>`           | Set to in_progress     |
| `tk close <id>`           | Set to closed          |
| `tk reopen <id>`          | Set back to open       |
| `tk status <id> <status>` | Manual status override |

## Relationships & Dependencies

| Relationship     | Command                        | Type                       |
| ---------------- | ------------------------------ | -------------------------- |
| Parent/child     | `tk create --parent <epic-id>` | Hierarchical               |
| Related tickets  | `tk link <id> <id> [id...]`    | Symmetric                  |
| Blocking/blocked | `tk dep <id> <dep-id>`         | Directed (id blocked by dep-id) |

```bash
# Epics: create campaign, then assign tasks
tk create "My Epic" -t epic
tk create "Subtask 1" --parent <epic-id>

# Dependencies: id cannot proceed until dep-id completes
tk dep <id> <dep-id>
tk dep tree <id>          # Visualize dependency graph (--full disables dedup)
tk dep cycle              # Detect circular dependencies
tk undep <id> <dep-id>    # Remove dependency

# Symmetric links
tk link <id1> <id2>
tk unlink <id> <target-id>
```

## Querying & Listing

| Command                 | Description                              |
| ----------------------- | ---------------------------------------- |
| `tk ls` / `tk list`     | List tickets (filter: `--status=X`, `-a X`, `-T X`) |
| `tk ready`              | Open/in-progress with all deps resolved  |
| `tk blocked`            | Tickets with unresolved dependencies     |
| `tk closed [--limit=N]` | Recently closed (default 20)             |
| `tk show <id>`          | Full ticket details                      |
| `tk query [jq-filter]`  | Export as JSON, optional jq filtering    |

Partial ID matching supported (e.g., `tk show 5c4` matches `nw-5c46`).

## Notes & Editing

```bash
tk add-note <id> [text]   # Append timestamped note (supports stdin)
tk edit <id>              # Open in $EDITOR (blocks agent processes — avoid)
```

## When to Use

- "create a ticket/task" or "remind me to" = `tk create`
- "what's next" = `tk ready`
- "what's blocked" = `tk blocked`
- "show me ticket X" = `tk show <id>`
