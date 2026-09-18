# Prepare Compose

Read only when creating or repairing the deployment model. Use the app's actual
commands, port, data paths and dependency requirements; templates are not evidence.

Keep `compose.yaml` useful locally. Put Shipd-specific settings in
`compose.deploy.yaml` using supported `x-` keys. Shipd remotely merges and validates
them during plan. Plain `ports` does not by itself request a public website.

For a service named `web` that really listens on port 3000, the minimum override is:

```yaml
services:
  web:
    x-public: true
    x-ingress-port: 3000
```

The base Compose must declare that container port through `ports` or `expose`.
`x-ingress-port` selects a declared port; without it HTTP ingress uses the first
declared one. Bind the app to `0.0.0.0`, not only `localhost`. Use the actual
production start command and a real readiness endpoint. Do not invent `/health`
or assume an image includes curl/wget. Build tools belong in the build stage.

Start with a platform URL via `x-public: true` unless the user requests a custom
domain. `x-domains: ["app.example.com"]` requests custom hosts and is independent
of `x-public`; never guess domain ownership or copy an example hostname into the
user's deployment. Plan returns admission requirements. For exact DNS records and the CLI 0.1.6
connection workflow, select the domains reference from the skill routing table.

For persistence, managed PostgreSQL or secret bindings, select the data-and-secrets
reference from the entry point only when the app needs them.

## Build arguments

Shipd supports standard Compose `build.args` for Dockerfile `ARG` values:

```yaml
services:
  nimbus:
    build:
      context: .
      args:
        APP_MODE: production
        PUBLIC_API_URL: ${PUBLIC_API_URL:-https://api.example.com}
```

Mapping and `KEY=value` list syntax use Compose's normal interpolation and
override merging. Values must come from the submitted project or explicit
Compose defaults; a remote build does not inherit your terminal's environment.
An explicit empty string overrides the Dockerfile default. An argument with no
resolved value is omitted, preserving the Dockerfile default. Changed arguments
produce a different image identity. These are ordinary build configuration;
secret-slot bindings remain runtime-only.

## Capability checks

The installed version's remote plan is authoritative about supported keys and
Compose fields. Treat unknown-key warnings and unsupported runtime semantics as
unresolved, not successful implementation. Fix the grounded problem or explain
the unsupported requirement; do not silently remove it.

Advanced networking, scaling, schedules and storage settings are unnecessary for
a basic first publish. When requested, consult just that feature in the official
documentation and validate the exact change with plan. Do not add platform orchestration
manifests, assume arbitrary `x-` keys work, or ask customers for platform operator
credentials.
