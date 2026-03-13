# Git Aliases

Custom aliases defined in `aliases.zsh`. Aliases above the OMZ section take precedence.

## Primary Aliases

| Alias   | Command                       | Description                                                                      |
| ------- | ----------------------------- | -------------------------------------------------------------------------------- |
| `gl`    | `git pull --prune`            | Pull and remove stale remote-tracking branches                                   |
| `glog`  | `git log --graph ...`         | Pretty graph log with author, message, refs, and relative date                   |
| `glogs` | `git log --graph ...`         | Same as `glog` but includes GPG signature status (slower — verifies each commit) |
| `gp`    | `git push origin HEAD`        | Push current branch to origin                                                    |
| `gd`    | `git diff --color \| sed ...` | Diff without `+`/`-` line prefixes (relies on color alone)                       |
| `gc`    | `git commit`                  | Commit                                                                           |
| `gca`   | `git commit -a`               | Stage all tracked changes and commit                                             |
| `gcb`   | `git copy-branch-name`        | Copy current branch name to clipboard                                            |
| `gb`    | `git branch`                  | List branches                                                                    |
| `gs`    | `git status -sb`              | Short status with branch info                                                    |
| `gac`   | `git add -A && git commit -m` | Stage everything and commit with inline message                                  |
| `ge`    | `git-edit-new`                | Open new/modified files in editor                                                |

## `glogs` Signature Indicators

`glogs` includes a GPG signature status character (via `%G?`) after each commit hash. This is separate from `glog` because GPG verification runs per-commit and is noticeably slower:

| Indicator | Meaning                       |
| --------- | ----------------------------- |
| `G`       | Valid signature               |
| `B`       | Bad signature                 |
| `U`       | Good signature, unknown trust |
| `X`       | Good signature, expired       |
| `Y`       | Good signature, expired key   |
| `R`       | Good signature, revoked key   |
| `E`       | Cannot verify (missing key)   |
| `N`       | Not signed                    |

## OMZ-Ported Aliases

The rest of the file contains aliases ported from the oh-my-zsh git plugin. See the [OMZ git plugin cheatsheet](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git#aliases) for the full reference, or scan `aliases.zsh` directly.

Notable groups: **add** (`ga`, `gaa`, `gapa`), **branch** (`gba`, `gbd`, `gbD`), **commit** (`gc!`, `gcn!`, `gcmsg`), **diff** (`gdca`, `gds`, `gdw`), **fetch** (`gf`, `gfa`), **log** (`glo`, `glol`, `glola`), **merge** (`gm`, `gmom`), **push** (`gpf`, `gpsup`), **rebase** (`grb`, `grbi`, `grbm`), **reset** (`grh`, `grhh`), **stash** (`gsta`, `gstp`, `gstl`), **switch** (`gsw`, `gswc`, `gswm`).

### Helper Functions

| Function             | Description                                                             |
| -------------------- | ----------------------------------------------------------------------- |
| `git_main_branch`    | Detects `main` or `master` (used by dynamic aliases like `gcm`, `grbm`) |
| `git_develop_branch` | Detects `dev`/`devel`/`development`/`develop`                           |
| `git_current_branch` | Returns the current branch name                                         |
| `grename old new`    | Rename a branch locally and on the remote                               |
