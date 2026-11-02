---
name: ct-skills:onboarding
description: Onboard an engineer onto the commercetools AI coding setup — omai profiles, shared baseline plugins and the Agatha LLM gateway for Claude Code and/or OpenCode. Use when someone asks to get set up, migrate to omai or Agatha, or move off their Claude Enterprise seat.
allowed-tools:
- Bash
- Read
- Glob
- Grep
- Write
- Edit
- AskUserQuestion
---

# Onboarding to omai and Agatha

**Run this from wherever you read it.** People get this skill as a link before
they have omai or any plugin, so you will often be reading it from GitHub or a
temporary checkout rather than as an installed skill. That is intended: follow
the steps below directly, resolving `references/` and `scripts/` relative to
this file. Do **not** install it under `~/.claude/skills/` first — it is a
one-off setup, and once omai is configured it arrives with the
`omai-ct-skills` plugin anyway.

Walks a commercetools engineer from an ad-hoc local agent setup to omai-managed
profiles. Work through the steps in order. **Never skip the backup, and ask
before anything that installs software, overwrites existing configuration or
switches the active profile.** `omai` and `oktapus` are distributed via Jamf, so
both should be installed; verify in step 0.

Facts used below (plugin specs, profile names) live here once; if they change,
change them here:

| thing | value |
| --- | --- |
| baseline plugin | `github:commercetools/omai-ct-baseline` |
| gateway plugin | `github:commercetools/omai-agatha-llm` |
| Claude Enterprise profile | `default` |
| gateway profile | `agatha` |
| target ids | `claude-code`, `opencode` |
| Claude Enterprise seats end | 2026-11-03 |
| budgets and prices | https://commercetools.atlassian.net/wiki/spaces/AIE/pages/3620012073 |
| support channel | `#ai-enablement-team` on Slack |

Do not hardcode model names anywhere except `references/intro.md`; the gateway
plugin owns the model pins. Do not quote budget amounts at all — they change per
group; point to the budgets page instead.

## 0. Preflight (read-only)

**Auto mode first.** Before running anything, tell the user: this setup runs a
script it just downloaded and rewrites the agent's own configuration (omai
renders into `~/.claude/` and `~/.config/opencode/`), and Claude Code's auto
mode blocks exactly that. Ask them to leave auto mode for this session
(shift+tab until the footer no longer says "auto mode on") so each step shows
an approval prompt instead. If a command is still denied by the classifier,
stop and say which one — never work around a denial.

Run and note the results:

- `omai --version` (needs 0.8.0 or newer), `oktapus --version`, `git --version`.
  Both CLIs come via Jamf. If `omai` is missing, offer the Homebrew install
  (`brew install commercetools/tap/omai`) and wait for the go-ahead. If `oktapus`
  is missing, stop: point the user to Jamf Self Service or the support channel,
  since nothing on the gateway works without it.
- `command -v claude opencode` — which target tools are installed
- `omai profile list` and `omai profile current` — is omai already in use?
- For each existing profile: `omai --profile <name> plugin list` and
  `omai --profile <name> target list`
- `gh auth status` — plugin repos are internal and cloned over HTTPS. If this
  fails, offer `gh auth setup-git` and wait for the user's go-ahead.

If omai has never been initialised (no `~/.config/oh-my-ai-shell/`), plan to run
`omai init` after the backup. It is idempotent and never overwrites.

If the user already uses omai, **their existing profiles and custom overlays
are theirs**: never edit or recreate a profile that exists without asking
(see step 5).

## 1. Explain

Read `references/intro.md` (next to this file) and show it to the user
**verbatim**. Do not paraphrase or regenerate it. Then ask whether to continue.

## 2. Ask

Use AskUserQuestion, one call with these questions (pre-mention what step 0
detected as installed):

1. **Which agent tools do you use today?** multi-select: Claude Code, OpenCode,
   Cursor, other (free text; other tools are backed up but not migrated).
   Cursor is not an omai target, so it can only be a source, never a destination.
2. **Which tools do you want to use going forward?** multi-select: Claude Code,
   OpenCode. Only these two are supported.
3. **Migrate custom configuration?** Yes / No. If yes and several tools are
   involved, clarify the direction (e.g. Claude Code → OpenCode).

## 3. Back up

Run `scripts/backup.sh` (next to this file). It copies Claude Code, OpenCode,
omai, Cursor, and Codex/Copilot configuration into
`~/.omai-onboarding-backup/<timestamp>/`, excluding session transcripts and
OpenCode credentials. Report the path to the user, and that the backup may
contain secrets. Do not continue if it fails.

## 4. Install missing tools

For each tool chosen in question 2 that step 0 found missing:

1. Pick the install method. On macOS with Homebrew, use it first:
   - OpenCode: `brew install anomalyco/tap/opencode` (upstream tap; the
     `homebrew/core` formula lags behind)
   - Claude Code: `brew install --cask claude-code`

   Without Homebrew, or if the brew install fails, fall back to the current
   official install script (look it up, do not rely on memory). Zscaler
   blocks some of these download sites for some users, so a 403 from the
   script URL most likely means that. Do not retry it — use Homebrew or point
   the user to the support channel.
2. Show the user the exact command and what it will change, and ask for
   confirmation. Never use `sudo` without explicit approval.
3. Install, then verify with `<tool> --version`.

If the user declines, drop that tool from the target list and say so.

## 5. Create profiles

Profiles to create — never overwrite an existing one:

| profile | create when | targets | plugins |
| --- | --- | --- | --- |
| `default` | the user chose or already has Claude Code, and today is before the seats end | `claude-code` only | baseline |
| `agatha` | always | the tools chosen in question 2 | baseline, gateway |

`default` is the user's direct-to-Anthropic setup on their Claude Enterprise
seat, the fallback while both still work. Say plainly that it stops reaching
Anthropic when the seats end. From that date on, do not create it; if it already
exists, leave it in place but recommend activating `agatha`.

If the user already has omai profiles, first ask which of them (if any) should
become the Claude Enterprise / Agatha profile instead of creating new ones. If a
profile with a target name already exists, show its plugins and targets and ask:
keep as is, add only what is missing, or use a different name. Plugins the user
has enabled in their current profile (team plugins such as `omai-saypetabyte`)
are not carried over automatically — list them and ask whether to add them to
the new profiles.

Per profile (pass `--profile` explicitly so the active profile never changes):

```sh
omai profile create <name>
omai --profile <name> target add claude-code --path ~/.claude/          # if chosen
omai --profile <name> target add opencode --path ~/.config/opencode/   # if chosen
omai --profile <name> plugin add -y github:commercetools/omai-ct-baseline
omai --profile agatha plugin add -y github:commercetools/omai-agatha-llm
omai --profile <name> render --dry-run             # show the user the result
```

`--path` is required: without a terminal, `target add` refuses to guess where
the tool's config lives. `profile create` does not switch profiles. Do **not** run a real `omai render`
yet: it writes to the live config of whatever target is enabled, and rendering
`agatha` before login would point the user's tools at a gateway they cannot
reach. Activation happens in step 7.

Notes to keep in mind:

- A plugin's `targets:` list in `plugin.yaml` only says what it was tested
  against; the profile's own targets decide where it renders. Set each profile's
  targets explicitly (above) and check the dry run shows the baseline rendering
  for every chosen target. Tell the user about anything that renders for one
  tool but not another.
- The baseline also bundles `omai-atlassian` (Jira/Confluence MCP, OAuth in the
  browser on first use). Mention it.
- A key a plugin manages overwrites a same-named key the user set by hand.
  Hand-written `ANTHROPIC_BASE_URL`/`ANTHROPIC_*_MODEL` settings or an OpenCode
  `ct-gateway` provider are taken over; mention this if the backup shows them.
- If the dry run reports drift or a plugin clone fails with status 128, fix
  git auth (`gh auth setup-git`) and retry.

## 6. Migrate custom configuration (only if the user said yes)

Migration means writing the user's custom configuration **directly into the
native config of the tool they are moving to**. Do not put it into omai
profiles or `custom/` overlays. omai only touches the keys and namespaced
paths it manages and leaves everything else alone, so the user's own config and
omai's profile output coexist and omai lands on top.

- Tool kept (e.g. Claude Code → Claude Code): nothing to migrate; the existing
  config stays in place.
- Tool added or switched (e.g. Claude Code → OpenCode): inventory the source
  from the backup (instructions, skills, agents, commands, MCP servers,
  permissions, hooks) and translate what has an equivalent into the target's
  native files (for OpenCode, under `~/.config/opencode/`). Check the target
  tool's current documentation for formats rather than guessing.
- Show the user the list of items and where each will be written, and get
  approval first. Copy, never move; the source stays untouched.
- Avoid keys omai manages in that target: the gateway `env`/provider entries
  and MCP entries from the profile's plugins. If the user's config sets one of
  those, tell them the plugin's value wins on render.
- Cursor as a source: from the backup's `cursor/` and `cursor-user/`, translate
  `mcp.json` MCP servers, `commands/` and any rules/skills into the destination
  tool. Global "User Rules" live in Cursor's app database, not in a file, so ask
  the user to paste them in and write them to the destination's instructions
  file. Project-level `.cursor/rules` and `.cursorrules` live in repos; offer to
  convert them per project only if asked. Editor settings and keybindings have
  no agent-tool equivalent: leave them in the backup.
- Say plainly what has no equivalent in the target tool (for example hooks in
  OpenCode) and skip it rather than approximating.

One exception: personal instructions. A hand-written `~/.claude/CLAUDE.md`
is not safe as it is — once any enabled plugin ships an `AGENTS.md`, omai
regenerates that file and the user's text drops out of it (the original is
saved once as `CLAUDE.md.pre-omai`). So, with the user's approval, move it
into each new profile's `custom/` plugin, which omai renders into
`~/.claude/CLAUDE.md` for Claude Code **and** `~/.config/opencode/AGENTS.md`
for OpenCode:

```sh
P=~/.config/oh-my-ai-shell/profiles/<name>/custom
cp ~/.claude/CLAUDE.md "$P/AGENTS.md"
[ -f "$P/plugin.yaml" ] || printf 'schema_version: 1\nname: custom\nversion: 0.1.0\ndescription: Personal instructions\n' > "$P/plugin.yaml"
```

The `plugin.yaml` is required: `custom/` is only loaded when it has one, and
without it the `AGENTS.md` is silently ignored. Never overwrite an existing
`custom/plugin.yaml` or `custom/AGENTS.md`; merge by hand with the user.

Afterwards run `omai --profile <name> render --dry-run` and confirm it reports
no conflicts with what was written.

## 7. Activate and verify

Ask which profile to activate now. Recommend `agatha`, but only after login:
environment and provider settings are read when a session starts, so an already
running session keeps its old routing (it will not break, nor will it be on the
gateway until restarted), while any session started before login would fail with
401. Logging in first avoids that.

1. Ask the user to run `! oktapus login` themselves (it opens a browser).
2. Check access: `oktapus whoami --json | jq -r '.groups[]' | grep agatha`.
   `app_agatha_users` and `app_agatha_llm_users` must both be present. Without the
   second, every LLM call returns 403 — tell the user to ask in
   `#ai-enablement-team` and stop before activating. `app_agatha_mcp_*` is needed
   for the MCP tools.
3. `omai profile use <chosen>` (flips the pointer and renders) and `omai doctor`.
4. If `agatha` is active, prove the gateway end to end with one real request per
   chosen tool, using the cheapest model so the check costs almost nothing:
   - Claude Code: `claude -p --model claude-haiku-5-5 "Reply with exactly: pong"`
   - OpenCode: `opencode run --model ct-gateway/claude-haiku-5-5 "Reply with exactly: pong"`

   Both run in a fresh process, so they pick up the new config even while this
   session still has the old one. Expect `pong`. A 401, 403 or connection error
   maps to the troubleshooting table below; do not call the setup done until
   each chosen tool answers.

If the user prefers not to activate yet, leave the active profile unchanged.

## 8. Summarise

Report concisely:

- what was backed up and where, what was installed, which profiles exist and
  which is active, what was migrated or skipped
- **next steps:** run `oktapus login` if not already done; restart the agent
  session (env is read at startup); in Claude Code check `/status` shows
  `http://127.0.0.1:8765`
- switching: `omai profile use default` for Anthropic directly (only until the
  Claude Enterprise seats end), `omai profile use agatha` for the gateway;
  `omai plugin update` then `omai render` to pull updates
- budgets: link the budgets page, and say that model choice is the biggest
  lever; `#ai-enablement-team` for 429s and access
- rollback: `omai profile use <previous>`, or restore from the backup path

## Troubleshooting

| symptom | fix |
| --- | --- |
| `plugin add` fails with status 128 | `gh auth setup-git`, retry |
| connection refused on `127.0.0.1:8765` | `oktapus service status`, or `oktapus forward` |
| 401 / not_authenticated | `oktapus login` |
| 403 on every LLM call | missing `app_agatha_llm_users` |
| 429 | daily/weekly budget used up; the response says when it resets (budgets page) |
| still talking to Anthropic | restart the session; `omai profile current` |
