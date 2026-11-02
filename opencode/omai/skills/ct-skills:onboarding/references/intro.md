## Welcome — what we're about to do

Until now, everyone at commercetools has run their own hand-installed,
hand-configured coding agent. We're moving everybody onto one shared,
simpler setup built around a tool called **omai**.

### The pieces

- **omai** (oh-my-ai-shell) manages your AI coding tool's configuration the
  way oh-my-zsh manages your shell. You switch on **plugins** — git repos that
  ship skills, MCP servers and shared instructions — and omai **renders** them
  into the tool's native config (`~/.claude/` for Claude Code,
  `~/.config/opencode/` for OpenCode). It merges its own keys into your files
  and leaves the rest of your settings alone.
- **Profiles** are independent omai configurations you can switch between with
  one command, e.g. "talk to Anthropic directly" vs. "talk through the gateway".
- **Agatha** is our internal agent gateway. It will be the way we reach LLMs:
  our Claude Enterprise seats end on **Nov 3**, and after that Agatha is the
  only route. It serves Claude Opus 5.5, Sonnet 5.5 and Haiku 5.5 to Claude
  Code and OpenCode, and Gemini 3.8 Flash and Gemini 4 Argon to OpenCode only.
- **oktapus** is a small CLI that logs you into Okta and runs a local proxy on
  `127.0.0.1:8765`. It attaches a fresh token to every request, so your tools
  never handle a credential.

### Budgets

Agatha limits spend per person, in money rather than tokens: one budget per day
and one per week, shared across all your machines and sessions. You're blocked
as soon as either runs out. Current amounts, reset times and prices:
https://commercetools.atlassian.net/wiki/spaces/AIE/pages/3620012073

Model choice is the biggest lever: Opus costs about twice as much as Sonnet and
about 40 times as much as Haiku. Gemini 4 Argon costs the same as Opus.

### What I'll do with you

1. Ask which agent tools you use today and which you want going forward
   (Claude Code and/or OpenCode), and whether to carry custom configuration over.
2. **Back up** your existing agent configuration (copy only, nothing deleted).
3. Install any chosen tool that's missing — **after asking you**.
4. Create omai profiles:
   - **default** (Claude Code only): baseline plugins, talking to Anthropic
     directly via your Claude Enterprise seat. Only if you use Claude Code, and
     only until Nov 3 — after that it no longer reaches Anthropic.
   - **agatha** (your chosen tools): baseline plugins + the Agatha LLM routing.
5. After you run `oktapus login`, switch you to the profile you choose and check
   with one real request per tool that it works.
6. Tell you what changed and what to do next.

I'll ask before anything risky, such as installing software or switching your
active profile.
