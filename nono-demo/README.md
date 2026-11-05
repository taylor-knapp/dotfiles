# nono

## Learnings

- You must always use `environment.allow_vars` to allow nono to pass HOME so that it can expand in set_vars or file reads in command profiles. Otherwise, nono will not expand $HOME in set_vars or file reads.
- Only a subset of env vars actually expand (e.g. HOME), and custome vars WILL NOT expand (e.g. GIT_SIGNING_KEY).
