# Git connection and CI

Git is optional for folder deployments. Only set up push/CI automation when
requested. Read `shipd git connect --help --json` for the installed binding
surface; read `shipd ci deploy --help --json` only for a CI-triggered deploy.

A binding needs positive repository installation, repository and owner IDs,
branch, path filters, CI policy and action policy. Obtain these from the user's
connected provider context; do not fabricate numeric IDs or silently select a
repository. Connecting returns a human authorization action. Its documented
continuation is `shipd git connect --resume <confirmation_id> --non-interactive`.

Install the registered [Shipd Deploy App](https://github.com/apps/shipd-deploy/installations/new)
on the repository's owning account and select the repository. The dashboard's
`https://app.shipd.cloud/git/install` provides the same link. If GitHub calls the
App private, its owner must make it public; customers cannot fix that with a
different CLI flag. Installation does not itself approve a Shipd binding.

Find the installation ID by opening **Configure** for Shipd Deploy in GitHub's
account or organization settings → Applications → Installed GitHub Apps. The
positive number at the end of that URL is `--repo-installation`. If the App's
Setup URL returns to `/git/install`, that page shows the option to give the agent.
Do not use `0`, and do not ask customers to mint an App token for `user/installations`.
Use `gh api repos/OWNER/REPO --jq '{repository_id: .id, owner_id: .owner.id}'`
for the repository and owner IDs with the customer's normal repository access.

The approval link is `/git/connect/<confirmation_id>` on the authenticated control
plane's public host. A project member with deploy authority clicks Approve or
Decline; no terminal code is needed. A pending resume returns the same action.
Expired or invalid installation-0 requests require a fresh connection request.

CI deployment uses the provider job's OIDC identity and a bound project. Do not
put a personal project token into workflow YAML or claim a normal laptop can
mint the CI job's identity. A pushed commit deploys its own Compose files; it
does not deploy uncommitted changes in the user's local folder. Use the installed
help to establish provider support instead of promising integrations from a roadmap.

OIDC removes the need for a personal Shipd token in CI; the GitHub App installation
is still required to fetch the source and report deployment results. There is no
OIDC-only installation-free binding in this implementation. `--ci-gate off` also
permits webhook-triggered deployment without waiting for CI: a workflow's `needs`
gate alone does not constrain that independent push path. Use a reviewed CI gate
when every push must wait for tests.
