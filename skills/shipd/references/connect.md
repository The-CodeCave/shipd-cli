# Install the CLI and connect a project folder

Read when installation, identity, or folder selection prevents the requested task.

## Install when `shipd` is missing

Check `shipd --version --json`. Installing this skill installs instructions only,
not the executable. If the CLI is missing, install it for the current system and
continue the user's task. Remote plan/deploy needs no local Docker or compiler.

With existing Homebrew on macOS (Apple Silicon/Intel) or Linux:

```sh
brew install The-CodeCave/tap/shipd
```

Without Homebrew, use the official checksum-verifying installer on macOS or
Linux (x86-64/ARM64). It installs to `~/.local/bin` without `sudo`; export PATH
in the calling shell so the next command can find it:

```sh
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/The-CodeCave/shipd-cli/releases/latest/download/install.sh | sh && export PATH="${SHIPD_INSTALL_DIR:-$HOME/.local/bin}:$PATH"
```

On x86-64 Windows in PowerShell:

```powershell
irm 'https://github.com/The-CodeCave/shipd-cli/releases/latest/download/install.ps1' | iex
```

The Windows installer adds `%LOCALAPPDATA%\Shipd\bin` to the current and user
PATH. `SHIPD_INSTALL_DIR` overrides the installer destination with an absolute
path; `SHIPD_VERSION=X.Y.Z` pins a version instead of `latest`. Set these in the
installer's environment if needed. Confirm success with `shipd --version --json`.
If a later tool shell has a stale PATH, use the installed executable's full path
or repeat the PATH setup there. Do not reinstall just to fix PATH.

For a missing command in an older CLI, use `brew upgrade The-CodeCave/tap/shipd`
for a Homebrew install or rerun its original installer. See the official
[distribution instructions](https://github.com/The-CodeCave/shipd-cli#install)
for release/platform details; do not guess an npm, pip, or Cargo package.

## Connect the intended identity

1. Use the application's root folder. A parent, child folder, or another checkout
   does not inherit Shipd authentication. Determine the working directory without
   dumping environment variables or reading credential storage.
2. Run `shipd auth status --non-interactive`. This reports credential provenance,
   not live verification: `source: stored`, `env`, or `none`. Inspect only returned
   metadata. `SHIPD_TOKEN` overrides a stored folder connection; never print its
   value. Resolve a conflicting identity with the human before deploying.
3. If credentials are missing, invalid, or expired, have the human open a terminal
   in this exact root and run `shipd auth`. They paste the project token into its
   hidden prompt. It is saved outside the repository. Do not collect it through
   agent chat, a command argument, or a tool call you can read.

The human can sign up and create their first project at
[Shipd](https://app.shipd.cloud). Setup provides the one-time token and an in-place
recovery action if token creation was interrupted. Do not create another project
just to recover a missing token. Do not rotate a working token silently.

In the dashboard, check the project's recorded owner (personal or organisation)
and environment before connecting. The environment's **Tokens** page can issue
a separately named token with a suitable preset and expiry, bounded by the
holder's current permissions. The bearer is shown once: the human pastes it
directly into `shipd auth`. A new named token leaves existing tokens working.
The dashboard owner selector does not switch a CLI folder's project or token.

Use the endpoint already selected by the user or their Shipd installation.
For a trusted custom installation, the human can use
`shipd auth --url '<trusted HTTPS origin>'`. Never change endpoints to make an
authentication error disappear, or remove `.shipd/project.json` automatically
to bypass a project mismatch. That file describes the folder connection.

If the user prefers browser sign-in, discover `shipd auth login --help --json`.
Its headless path is `shipd auth login --no-browser --non-interactive`; relay the
returned device URL/code and retain the running command or returned recovery
instructions. This alternative is not required for token-paste onboarding.

Once connected, return to the requested task. Do not repeat authentication on
every command. Never turn `auth logout` into a harmless probe: it removes the
folder credential and may revoke it remotely.
