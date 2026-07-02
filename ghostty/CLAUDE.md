# Searching Ghostty Docs

Don't guess Ghostty config keys or scrape the website (ghostty.org returns **403** to
automated fetchers). Ghostty ships its entire reference locally and via the CLI — search
that instead.

## Primary: `+show-config --default --docs`

Dumps **every** config option with its default value and inline doc comment to stdout:

```sh
ghostty +show-config --default --docs
```

Grep it to answer "what's the key for X" / "what values does it take":

```sh
ghostty +show-config --default --docs | grep -iA8 'background-opacity'
ghostty +show-config --default --docs | grep -iB1 -A6 'shell-integration'
```

Output quirk: keys with no default print as `font-family =` (empty value). That's valid
syntax meaning "use the default" — it exists so the doc comment has something to attach to.

## The binary isn't on `$PATH` (macOS)

Ghostty doesn't symlink a CLI by default. The real binary lives in the app bundle:

```sh
/Applications/Ghostty.app/Contents/MacOS/ghostty +show-config --default --docs
```

Add an alias/PATH entry if you use it often (none set in this topic yet). Note: running
the bundled binary **fails inside this repo's sandbox** (`Library not loaded: Sparkle.framework
… blocked by sandbox`), so run doc lookups with the `!` prefix / outside the agent sandbox.

## Full local docs dump: `ghostty-docs.txt`

This dir can hold a complete offline dump of the Ghostty reference at
`ghostty/ghostty-docs.txt` (gitignored — machine-specific, regenerate on demand).
**Read this file first** to answer config/keybind/theme questions — it's the whole
reference in one grep-able file, no network, no 403.

```sh
grep -iA8 'background-opacity' ~/.dotfiles/ghostty/ghostty-docs.txt
```

### Generate / refresh it

`install.sh` runs `dump-docs.sh` once and installs a **daily cron job** (09:00) so the
dump tracks Ghostty upgrades automatically. To regenerate on demand:

```sh
bash ~/.dotfiles/ghostty/dump-docs.sh
```

Run it **outside the agent sandbox** (the bundled binary needs Sparkle.framework, blocked
inside) — use the `!` prefix in Claude Code, or a normal shell. The script finds `ghostty`
on `$PATH` or falls back to `/Applications/Ghostty.app`, and bundles config ref +
keybind actions + keybinds + themes + the bundled markdown docs into the dump.

### Staleness rule (do this when you read the file)

A daily cron normally keeps this fresh, but cron can be disabled or the machine asleep, so
still verify: the first line carries `generated <ISO-date>`. Compare it to today's date.
**If the dump is older than 30 days (or missing), tell the user** it's stale and to
regenerate with the command above — Ghostty config keys change between releases, so a stale
dump can be wrong. Don't silently trust an old dump.

## All CLI actions (prefix with `+`)

| Action | Use |
| ------ | --- |
| `+show-config --default --docs` | Full config reference (the main one) |
| `+show-config` | Your *current* effective config |
| `+validate-config` | Check a config file for errors |
| `+list-keybinds` | All active keybindings (`trigger=action`) |
| `+list-actions` | All keybinding *actions* (for use in keybinds, not all runnable as CLI) |
| `+list-themes` | Hundreds of built-in themes (set with `theme = <name>`) |
| `+list-fonts` | Installed fonts — use to confirm a `font-family` name |
| `+list-colors` | Named colors |
| `+show-face` | Inspect font face resolution |
| `+help`, `+version` | — |

## Offline docs in the bundle

Same reference, generated from one source, also lives on disk (created at install):

- Markdown + HTML: `/Applications/Ghostty.app/Contents/Resources/ghostty/docs/`
- Man pages: `/Applications/Ghostty.app/Contents/Resources/man/` (`man 5 ghostty`)

(On macOS `$prefix` = the app bundle's `Contents/Resources`.)

## Online (for humans, not the fetcher)

- Option reference: https://ghostty.org/docs/config/reference
- Keybind/action reference: https://ghostty.org/docs/config/keybind/reference
