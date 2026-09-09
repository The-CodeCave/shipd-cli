# Shipd CLI

This repository distributes the official prebuilt `shipd` command-line client. The build source remains in Shipd's private source-of-truth repository; every release records its source revision and SHA-256 checksums in `release.json` and `SHA256SUMS`.

Release availability is visible on the repository's [Releases page](https://github.com/The-CodeCave/shipd-cli/releases). If no published release exists yet, the commands below are staged and become active with the first `vX.Y.Z` release.

## Install

Homebrew on Apple Silicon, Intel macOS, or Linux:

```sh
brew install The-CodeCave/tap/shipd
```

Verified installer on Apple Silicon, Intel macOS, x86-64 Linux, or ARM64 Linux:

```sh
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/The-CodeCave/shipd-cli/releases/latest/download/install.sh | sh && export PATH="${SHIPD_INSTALL_DIR:-$HOME/.local/bin}:$PATH"
```

PowerShell on x86-64 Windows:

```powershell
irm 'https://github.com/The-CodeCave/shipd-cli/releases/latest/download/install.ps1' | iex
```

The Unix installer writes to `~/.local/bin` without `sudo`; the command above makes it available in your current terminal immediately. The installer also prints the exact command for connecting the folder if a later terminal cannot find `shipd`. The Windows installer writes to `%LOCALAPPDATA%\Shipd\bin` and adds that directory to both the current PowerShell and user PATH. Set `SHIPD_INSTALL_DIR` to an absolute directory to override the destination. Set `SHIPD_VERSION=0.1.0` to pin a release instead of installing `latest`.

Confirm the installed artifact:

```sh
shipd --version
```

## Connect

Open a terminal in your project's root folder, then run:

```sh
shipd auth
```

Paste the agent token from your Shipd project into the hidden prompt. Shipd verifies the token and saves it outside your repository, bound to this exact folder. Subfolders and other checkouts need their own connection.

Open your coding agent in the same folder and say:

> Deploy this project to Shipd.

The agent inspects your app with `shipd doctor`, prepares the Compose files, previews the changes with `shipd plan`, and publishes with `shipd deploy` (also named `shipd apply`). Shipd uploads the current source and runs builds and deployment on its managed executor. You do not need local Docker, cluster credentials, or a Git connection to deploy this way.

The CLI uses Shipd's official endpoint automatically. `shipd auth login` also supports browser sign-in. Self-hosted operators can choose a trusted endpoint with `shipd auth --url <https-origin>`.

Deployment output includes the public checks for DNS, TLS, HTTP responses, redirect loops, and broken critical assets. `publication.verified_urls` contains only URLs whose checks passed. A failed public check preserves the completed deployment and its operation ID; `shipd operations resume <operation_id>` rechecks it without deploying again. If the agent needs a secret or approval, it gives you the exact page to complete, then resumes the same uploaded source.

`shipd plan`, `shipd deploy`, and operation resumes emit JSON Lines in `--json` mode: progress when the execution state changes, then one final result. A pending execution exits 2 and retains its resume command. A completed apply whose public checks fail exits 1 with `state: succeeded` and `publication.status: failed`; use its resume command to recheck DNS/TLS readiness, or `shipd status` for diagnosis.

## Give your agent the Shipd skill

The optional [Shipd skill](https://github.com/The-CodeCave/shipd-cli/tree/main/skills/shipd) teaches your agent the publishing
and recovery workflow. Install it from your application's root folder:

```sh
npx skills add The-CodeCave/shipd-cli --skill shipd
```

Choose your agent in the installer's prompts. This uses the
[open Agent Skills installer](https://github.com/vercel-labs/skills) and requires
Node.js; it installs instructions, not Shipd credentials. You can also copy the
entire `skills/shipd` directory from the public repository into your agent's supported skills location.
Keep `references/` beside `SKILL.md`. For Codex, a project installation belongs in
`.agents/skills/shipd`; for Claude Code, `.claude/skills/shipd`. Follow your client's
skill discovery/reload instructions, then ask it to deploy the project to Shipd.

The skill exposes a short description for discovery, a small overview when
selected, and eight independent references loaded only for the current task. It
uses the installed CLI's command-specific help when needed. Do not paste all of
its files into a system prompt or AGENTS.md: that defeats progressive disclosure.
The folder CLI works without the skill; installing it adds no authentication step.

## Automation and agent shells

Every ordinary command in this public `shipd` binary supports the global `--non-interactive` mode. It
implies JSON output, never opens a browser, never prompts, and is safe with stdin closed. A shell
without a TTY also suppresses interactive effects; add `--non-interactive` whenever an automation
consumer needs the machine-output contract explicitly.

The equivalent environment switch is `SHIPD_NON_INTERACTIVE=1`, which is useful when a runner
injects execution policy separately from argv.

```sh
shipd --non-interactive status
shipd --non-interactive confirmations watch cnf-01JEXAMPLE --timeout 15m
shipd --non-interactive auth login --label ci-runner
SHIPD_NON_INTERACTIVE=1 shipd status
```

Machine-readable global and per-command help describe required parameters, accepted flags,
defaults, and environment or stored-credential sources. Missing inputs return the same information
as structured JSON, including every missing parameter, so an agent can construct the next argv
without parsing prose:

```sh
shipd --help --json
shipd confirmations watch --help --json

# Exit 2 with a structured missing-parameter response for confirmation_id.
shipd --non-interactive confirmations watch
```

For authentication, `auth login --non-interactive` emits JSON Lines: a pending record containing
the verification URL and user code appears before polling, followed by one final success or error
record. Secrets are never accepted as a raw command-line argument; use `SHIPD_TOKEN` or the
folder-scoped credential created by `shipd auth`. Automation may explicitly supply one token line
through `shipd auth --token-stdin --non-interactive`; ordinary non-interactive commands never prompt.
Parse and runtime-bootstrap failures are
also structured as `shipd.envelope/v2` in machine mode; v2 adds the retry-oriented `error.help`
object without changing the published `shipd.envelope/v1` contract.

Exit codes retain their stable meanings: `0` success, `1` command failure, `2` invocation or usage
failure, and `3` a structured human action is required. `shipd mcp` is the one stdin/stdout
exception: it speaks the MCP protocol over stdio instead of emitting ordinary CLI JSON. The
separately built human-approver utility `shipd-ops` is not part of the public CLI or this
non-interactive contract.

## Deploying from CI without a token

`shipd ci deploy` deploys the commit a CI job checked out **without any Shipd credential in the
repository**. The job asks its CI provider for a short-lived OIDC id-token, the control plane
verifies that token against a binding a human already reviewed, and it returns a ten-minute,
read-only capability scoped to exactly one deploy intent. There is nothing to rotate and nothing a
repository secret could hold.

```sh
# In a GitHub Actions job with `permissions: id-token: write`.
shipd ci deploy --project shop --json
shipd ci deploy --project shop --no-wait
shipd ci deploy --project shop --wait-timeout 300
```

`--issuer` accepts `github-actions` today and refuses anything else by name. The id-token is minted
for the control plane's own origin as its audience, so a token minted for one control plane is
worthless at another; `--audience` (or `SHIPD_OIDC_AUDIENCE`) overrides that only when the operator
has configured a different one on both sides. `--wait-timeout` defaults to 600 seconds and may not
exceed 600 — the capability's own life.

Exit codes follow the ordinary contract with one thing worth reading twice. A deploy that is
waiting for CI evidence exits **0**, not 1 and not 2: when the binding gates on the very workflow
run that called this command, waiting for that evidence would deadlock the run. `succeeded`,
`awaiting_ci` and `awaiting_action` exit 0; `failed` and `superseded` exit 1; a `--wait-timeout`
that elapses exits 2 **with the intent still running** — re-run the command to wait again, on the
same commit and therefore the same intent.

The id-token and the capability appear in no output, log line or diagnostic, even when the control
plane echoes them back inside a refusal message. A pending human action is printed with its URL and
host but never its verification code: that belongs to the person approving on the dashboard, and a
CI log is a broadcast channel.

For GitHub Actions, prefer the official Action, which pins an exact CLI version and verifies its
checksum before executing anything.

## Verification and platform status

Installers verify the selected archive against the release's `SHA256SUMS` before replacing an existing binary. Linux archives are statically linked musl binaries. Windows is built and smoke-tested as a first-class release target, but receives less field coverage than Apple Silicon and Linux today.

macOS binaries from v0.1.1 onward are Developer ID signed with hardened runtime and accepted by Apple’s notarization service before publication. Version v0.1.0 remains unsigned. The standalone executable cannot carry a stapled notarization ticket, so Gatekeeper may need network access to retrieve Apple’s ticket on first use. Linux and Windows do not yet have independent artifact signatures; SHA-256 checksums verify download integrity.

See [SECURITY.md](SECURITY.md) for private vulnerability reporting and [LICENSE](LICENSE) for the binary distribution terms.
