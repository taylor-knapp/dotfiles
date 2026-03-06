# Magnet Window Manager

Custom window layout overrides managed via dotfiles.

## Grid System

Magnet uses a **24x12 grid** for horizontal commands (columns x rows) and **12x24** for vertical. A `frame` is `[[x, y], [w, h]]` where coordinates are grid cells from the top-left origin.

Examples:
- Full screen: `[[0, 0], [24, 12]]`
- Left half: `[[0, 0], [12, 12]]`
- Right ~80%: `[[5, 0], [19, 12]]`

## Modifier Keys (Carbon)

| Value | Modifier |
|-------|----------|
| 256   | Shift |
| 2048  | Ctrl |
| 4096  | Alt/Opt |
| 6144  | Ctrl+Alt |
| 8192  | Cmd |

Combine by adding values (e.g., Ctrl+Alt = 2048 + 4096 = 6144).

## Key Codes (Carbon)

| Code | Key |
|------|-----|
| 17   | T |
| 34   | I |

## Current Overrides

| Command | Frame | Shortcut | Notes |
|---------|-------|----------|-------|
| `rightTwoThirds` | `[[5,0],[19,12]]` | Ctrl+Alt+T (default) | Widened to ~80% right-aligned |
| `iTerm` | `[[5,0],[19,8]]` | Ctrl+Alt+I | Custom app-specific command |

## Adding Overrides

Edit the `OVERRIDES` dict in `set-defaults.py`. Each key is the command `name`, and the value is a dict of fields to patch (e.g., `frame`, `keyCode`, `modifiers`).

## Applying

```sh
python3 magnet/set-defaults.py
# Then restart Magnet (or quit and reopen)
```
