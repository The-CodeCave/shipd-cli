# Connect a project folder

Read when installation, identity, or folder selection prevents the requested task.

1. Use the application's root folder. A parent, child folder, or another checkout
   does not inherit Shipd authentication. Determine the working directory without
   dumping environment variables or reading credential storage.
2. Check `shipd --version --json`. If missing, use the official distribution's
   [installation instructions](https://github.com/The-CodeCave/shipd-cli#install)
   for this operating system. Install the CLI only; remote plan/deploy does not
   need local Docker. If installation just finished but PATH is stale, use the
   installer's printed PATH setup or executable path.
3. Run `shipd auth status --non-interactive`. This reports credential provenance,
   not live verification: `source: stored`, `env`, or `none`. Inspect only returned
   metadata. `SHIPD_TOKEN` overrides a stored folder connection; never print its
   value. Resolve a conflicting identity with the human before deploying.
4. If credentials are missing, invalid, or expired, have the human open a terminal
   in this exact root and run `shipd auth`. They paste the project token into its
   hidden prompt. It is saved outside the repository. Do not collect it through
   agent chat, a command argument, or a tool call you can read.

The human can sign up and create their first project at
[Shipd](https://app.shipd.cloud). Setup provides the one-time token and an in-place
recovery action if token creation was interrupted. Do not create another project
just to recover a missing token. Do not rotate a working token silently.

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
