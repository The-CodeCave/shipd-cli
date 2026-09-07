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
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/The-CodeCave/shipd-cli/releases/latest/download/install.sh | sh
```

PowerShell on x86-64 Windows:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm 'https://github.com/The-CodeCave/shipd-cli/releases/latest/download/install.ps1' | iex"
```

The Unix installer writes to `~/.local/bin` without `sudo`. The Windows installer writes to `%LOCALAPPDATA%\Shipd\bin` and adds that directory to the user PATH. Set `SHIPD_INSTALL_DIR` to an absolute directory to override the destination. Set `SHIPD_VERSION=0.1.0` to pin a release instead of installing `latest`.

Confirm the installed artifact:

```sh
shipd --version
```

## Connect

The CLI uses the official Shipd proof-of-concept control plane by default. Copy an environment token from the Shipd dashboard, then export it in your shell:

```sh
export SHIPD_TOKEN='...'
shipd status
```

PowerShell uses `$env:SHIPD_TOKEN = '...'`. Self-hosted operators can override the endpoint with `SHIPD_CONTROL_PLANE_URL`; ordinary users do not need to set it.

Installing the CLI does not grant Kubernetes or registry credentials. Remote inspection commands use the control plane, while `shipd plan` and `shipd apply` currently require a Shipd-managed execution host with cell access. Hosted Apply from an arbitrary laptop or CI runner is not enabled yet.

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
folder-scoped credential created by `shipd auth login`. Parse and runtime-bootstrap failures are
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

The current macOS artifacts are not Developer ID signed or notarized. Releases also do not yet include cryptographic artifact signatures beyond SHA-256 checksums. These are explicit pre-GA limitations, not guarantees implied by this repository.

See [SECURITY.md](SECURITY.md) for private vulnerability reporting and [LICENSE](LICENSE) for the binary distribution terms.
