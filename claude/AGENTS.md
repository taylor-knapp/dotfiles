# Agent Instructions: nijacat

## Style
- Chat replies: use caveman ultra compression with simple English plain rules. Drop articles, filler, hedging, and pleasantries. Fragments are allowed. Use short sentences and active voice. Use one word for one meaning. Define technical terms once. Do not use em-dashes or contractions. For documents, code, commits, and security warnings, use the simple English document rules and complete sentences.
- Plans: keep plans very short. End each plan with unresolved questions.
- Ask questions as plain text, then stop. Never use AskUserQuestion. It times out after about 60 seconds and continues on its own.

## Self-updates
If the user says "Remember," "update yourself," "add a memory," or "forget," edit `~/.dotfiles/claude/AGENTS.md`.
Auto-memory (notes on incidental discoveries) lives in `~/.dotfiles/claude/memory/`. Put durable rules in `~/.dotfiles/claude/AGENTS.md`.

## Writing
- Pull request (PR) descriptions: write in the first person and a relaxed tone. Use `## Summary` (one or two sentences that give the reason) and `## Review Context` (two or three bullets that give insight, not a list of every change).
- Code comments describe only the current code. Do not write comments such as "unlike the earlier approach." PR iteration history stays in the conversation.
- Use OpenSpec design IDs, such as D8, only inside OpenSpec documents. In code and tests, state the decision directly.
- For configuration repositories (nvim, dotfiles), suggest a CHANGELOG.md entry.

## Tools
- For TypeScript and JavaScript symbol lookups, prefer LSP (language server protocol) over Grep.
- To read GitHub file content, use `gh api repos/{owner}/{repo}/contents/{path}`. Never use raw.githubusercontent.com or WebFetch, because each one is a prompt-injection route (a way for outside text to steer the agent).
- Tickets: use the `tk` command-line tool. Run `tk help` for help. If the user says "remind me" or "create ticket," run `tk create`. If the user says "what's next," run `tk ready`.
- For Neovim, read `~/.config/nvim/README.md` first.
- For macOS `defaults` commands, use `/macos-defaults`.
- Hook scripts: write messages for Claude to stderr (`>&2`).
- Make sure that a file exists by using Read, not `test -f`. Discard unneeded standard output (stdout) by redirecting it to `> /dev/null`.
- There is no local pnpm store (the cache of installed packages). If the global store is not available, tell the user.
- Claude Code docs map: https://code.claude.com/docs/en/claude_code_docs_map.md
- If you run `find` over a repo, prune `.git` and `.terraform` directories. The nono sandbox denies some paths inside them, so `find` fails with `Operation not permitted`. Use `rtk find <root> \( -name .git -o -name .terraform \) -prune -o <tests> -print`. For example, `rtk find packages-backend \( -name .git -o -name .terraform \) -prune -o -path '*sync-actions*' -name '*.ts' -print`.

## Validation (TS/pnpm)
Make "Validate changes" the final todo. Run these steps in this order: prettier, typecheck, eslint, then related tests. Fix all errors, warnings, and deprecations.
- For a file `F`, run these commands in order:
  1. `pnpm exec prettier --write F`
  2. `pnpm --filter ./packages/PKG typecheck`
  3. `pnpm exec eslint F`
  4. Run related tests: `pnpm exec jest --findRelatedTests F` for Jest, or `pnpm exec vitest related F --run` for Vitest.
- Monorepo: run these commands in order: `pnpm format`, `pnpm typecheck`, `pnpm lint`, `pnpm test`.

## Git
- Never use `git -C <dir>`. Run git commands in the current directory.
- Begin branch names with a ticket ID, such as `UAA-5125-*`.
- Use `origin/main` as the base reference (the branch to compare against), not `main`. For example, run `git diff origin/main...HEAD`.
- For refactors, make a separate `git commit --fixup=<target>` for each target commit. Find each target commit with `git log origin/main..HEAD --oneline -- FILE`. To squash, run `git stash` first. Then run `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash origin/main`. The `--autosquash` option requires `-i`.

## RTK

- Proactively wrap commands with the `rtk` prefix. For example, use `rtk git diff origin/main...HEAD`, not `git diff origin/main...HEAD`.
- Most used commands: grep, git, pnpm, ls, find, curl, wc, rg, gh, tsc, prettier, npx, diff.
- Prefix every command segment, not only the first. In `a; b`, `a | b`, and `a && b`, write `rtk a; rtk b`.
- If a Bash call is denied with "a hook changed this call's input", the error quotes the rewritten command after "The hook produced this input". In your next response, call Bash again with exactly that `command` and `description`. Send no other text and no other tool call, except other denied calls of the same kind. Do not switch to another tool. Do not edit the command. If the second attempt is also denied, stop and tell the user.
- For help, run `rtk help` for the command list, `rtk <command> --help` for one command, or `rtk rewrite "<command>"` to see the rtk form of a command.

@RTK.md
