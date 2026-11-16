# nono

## Setting Up Nono

### Pre-requisites

#### Create a limited Github credential

Create [a fine grain personal access token](https://github.com/settings/personal-access-tokens) with the following:
- access the commercetools organization
- all repositories
- *actions*: read only
- *commit statuses*: read only
- *content*: read and write
- *issues*: read only
- *pull requests*: read and write
- *metadata*: read only (will likely be checked by default)

Add it to keychain
```
security add-generic-password -U -s nono -a github_commercetools -w "<token>"
```

#### Install nono

Pull the [uaa-shared](https://github.com/commercetools/uaa-shared) repo latest, and go to `taylor.knapp/nono`.

Run the `sh install.sh` script to install nono and it's dependencies.
- Add the new gpg key to github
- Save the passphrase to dashlane.
#### Prepare a local copy of the zscaler certificate

Copy the zscaler certificate locally so we can use it in proxy requests.

```
security find-certificate -a -p -c "Zscaler Root CA" > ~/.certs/zscaler-root-ca.pem
```

#### Add env vars

Add an `.env` file and each variable.

## How does nono work?

From the [quickstart](https://nono.sh/docs/cli/getting_started/quickstart):

> nono wraps any command with an OS-level sandbox. You specify what the command is allowed to access, and nono enforces those restrictions at the kernel level.
### Profiles & Groups

From the [docs](https://nono.sh/docs/cli/features/profiles-groups):

> Profiles are pre-configured capability sets that define what a sandboxed process can access. Groups are the composable building blocks that profiles are made from. Together they codify security policy so you don’t have to specify flags manually every time.

In other words, profiles are
- extensible and composable full profiles to control nono's behavior
- that contain groups that control file/command access
- and also other basic profile setup like [developer network access](https://nono.sh/docs/cli/features/networking#network-profiles)

While groups
- deny access to specific sensitive dirs/files
- allow access to specific required dirs/files
- deny access to dangerous commands (e.g. `rm`, `sudo`, etc.)

We set up the following:
- A `base` profile with general setup to facilitate node development (extends the `node-env` profile)
- A `commercetools` profile with ct specific stuff
- A `nolabs-ai-claude` profile that copies the `nolabs-ai/claude` packaged profile but disables keychain access
- A `personal` profile with your own personal stuff
- And finally, a `claude-code` profile that brings it all together

## Learnings

- You must always use `environment.allow_vars` to allow nono to pass HOME so that it can expand in set_vars or file reads in command profiles. Otherwise, nono will not expand $HOME in set_vars or file reads.
- Only a subset of env vars actually expand (e.g. HOME), and custome vars WILL NOT expand (e.g. GIT_SIGNING_KEY).
