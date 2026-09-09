# Git connection and CI

Git is optional for folder deployments. Only set up push/CI automation when
requested. Read `shipd git connect --help --json` for the installed binding
surface; read `shipd ci deploy --help --json` only for a CI-triggered deploy.

A binding needs the real repository installation, repository and owner IDs,
branch, path filters, CI policy and action policy. Obtain these from the user's
connected provider context; do not fabricate numeric IDs or silently select a
repository. Connecting returns a human authorization action. Its documented
continuation is `shipd git connect --resume <confirmation_id> --non-interactive`.

CI deployment uses the provider job's OIDC identity and a bound project. Do not
put a personal project token into workflow YAML or claim a normal laptop can
mint the CI job's identity. A pushed commit deploys its own Compose files; it
does not deploy uncommitted changes in the user's local folder. Use the installed
help to establish provider support instead of promising integrations from a roadmap.
