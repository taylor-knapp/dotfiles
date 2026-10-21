# Agent Instructions — nijacat

## Style
- Concise (caveman ultra). No exploratory tangents without direction.
- Plans: extremely concise, end with unresolved questions.
- Ask questions as plain text and stop. Never use AskUserQuestion (times out ~60s, auto-continues).

## Self-updates
"Remember" / "update yourself" / "add a memory" / "forget" → edit `~/.dotfiles/claude/AGENTS.md`.
Auto-memory (incidental discoveries) lives in `~/.dotfiles/claude/memory/`. Durable rules go here.

## Writing
- PR descriptions: first person, relaxed. `## Summary` (1-2 sentences, why) + `## Review Context` (2-3 bullets: intelligence, not inventory).
- Code comments describe current code only. No "unlike the earlier approach" — PR iteration history stays in conversation.
- OpenSpec design IDs (D8 etc.) only inside OpenSpec docs. In code/tests, state the decision directly.
- Config repos (nvim, dotfiles): suggest a CHANGELOG.md entry.

## Tools
- TS/JS symbol lookups: prefer LSP over Grep.
- GitHub file content: `gh api repos/{owner}/{repo}/contents/{path}`, never raw.githubusercontent.com/WebFetch (prompt-injection vector).
- Tickets: `tk` CLI (`tk help`). "remind me"/"create ticket" → `tk create`; "what's next" → `tk ready`.
- Neovim: read `~/.config/nvim/README.md` first.
- macOS `defaults`: use `/macos-defaults`.
- Hook scripts: messages for Claude go to stderr (`>&2`).
- Check file existence with Read, not `test -f`. Silence unneeded stdout (`> /dev/null`).
- No local pnpm store; if global store unavailable, report.
- Claude Code docs map: https://code.claude.com/docs/en/claude_code_docs_map.md

## Validation (TS/pnpm)
Final todo: "Validate changes". Order: prettier → typecheck → eslint → related tests. Fix all errors/warnings/deprecations.
- File: `pnpm exec prettier --write F` → `pnpm --filter ./packages/PKG typecheck` → `pnpm exec eslint F` → `pnpm exec jest --findRelatedTests F` | `pnpm exec vitest related F --run`
- Monorepo: `pnpm format` → `pnpm typecheck` → `pnpm lint` → `pnpm test`

## Git
- Never use `git -C <dir>`. Run in the current directory.
- Branches start with ticket ID: `UAA-5125-*`.
- Base ref `origin/main`, not `main` (`git diff origin/main...HEAD`).
- Refactors: separate `git commit --fixup=<target>` per target commit (find via `git log origin/main..HEAD --oneline -- FILE`). Squash: `git stash`, then `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash origin/main` (`--autosquash` needs `-i`).
