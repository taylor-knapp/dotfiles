# nono

Profiles live in `profiles/` and are symlinked to `~/.config/nono/profiles`. Before you edit a profile, use the nono CLI to learn the format. Do not guess field names or values.

## Learn the profile format

```sh
nono profile guide                    # Field reference: intent, allowed values, merge rules
nono profile schema                   # JSON Schema for profile files
nono profile init x --full            # Skeleton that contains every key
nono profile groups                   # Policy groups for groups.include/exclude
nono profile groups <name>            # Rules in one group
```

`profile.schema.json` is a local copy of `nono profile schema`. If nono is updated, regenerate it:

```sh
nono profile schema > nono/profile.schema.json
```

## Inspect and validate

```sh
nono profile list                     # Built-in, pack, and user profiles
nono profile show <name>              # Fully resolved profile, after extends
nono profile diff <a> <b>             # Compare two profiles
nono profile validate <name|path>     # Validate a profile
nono why ...                          # Show why one access is allowed or denied
```

After each profile change, run `nono profile validate` and `nono profile show`.

## Merge rules

- Arrays are appended and de-duplicated. A child profile cannot remove an inherited filesystem path.
- Maps merge. The child key wins on a conflict.
- To drop an inherited group, use `groups.exclude`.
- nono does not discover a profile in a repo automatically. Pass it with `--profile <path>`.

## Known gotchas

- `env_credentials` resolve to phantoms (`nono_` + 64 hex) once any `command_policies.commands` entry is live. An empty `commands` map is fine. `agent-base` has a live `gpg` entry, so every profile that extends it gets phantoms. Tested with `mcp` plus one `gpg` entry: the sandbox saw 69 chars, not the real 76.
- The AG client secrets are exported by `claude-nono` from the keystore instead of `env_credentials`. Add a new AG account to the list in `claude-nono`, not to a profile.
