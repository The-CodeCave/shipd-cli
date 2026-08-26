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

## Verification and platform status

Installers verify the selected archive against the release's `SHA256SUMS` before replacing an existing binary. Linux archives are statically linked musl binaries. Windows is built and smoke-tested as a first-class release target, but receives less field coverage than Apple Silicon and Linux today.

The current macOS artifacts are not Developer ID signed or notarized. Releases also do not yet include cryptographic artifact signatures beyond SHA-256 checksums. These are explicit pre-GA limitations, not guarantees implied by this repository.

See [SECURITY.md](SECURITY.md) for private vulnerability reporting and [LICENSE](LICENSE) for the binary distribution terms.
