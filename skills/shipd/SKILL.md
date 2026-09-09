---
name: shipd
description: Deploy and operate a user's application on Shipd using its CLI or an available Shipd MCP connection. Use for Shipd publishing, project connection, deployment approvals, and diagnosed failures. Not for developing the Shipd platform itself or deploying to other clouds.
---

# Shipd

Shipd is a managed cloud operated by the user's coding agent. Standard
`compose.yaml` plus `compose.deploy.yaml` describe the app; Shipd builds and runs
it remotely. The dashboard shows state and completes human actions. Customers
do not need Kubernetes credentials, local Docker, or a Git remote to publish.

## Load only the current task

Choose **one** reference below for the immediate task. Read another only when
an observed result or the user's request needs it. References are independent;
do not preload, concatenate, or recursively read this directory. Do not copy the
whole skill into AGENTS.md, CLAUDE.md, or persistent memory. Retain only a small
handoff: project folder, operation ID, current state, next action.

| Immediate need | Read |
|---|---|
| Missing CLI, authentication, or wrong folder | [connect](references/connect.md) |
| First publish, changed source, or interrupted deployment | [deploy](references/deploy.md) |
| Create or repair Compose and public HTTP exposure | [compose](references/compose.md) |
| `action_required`, pending approval, or secret entry | [actions](references/actions.md) |
| Inspect health or investigate a failed public check | [diagnose](references/diagnose.md) |
| App needs persistent data, PostgreSQL or secret bindings | [data and secrets](references/data-and-secrets.md) |
| User requests MCP or the client needs a connection | [MCP](references/mcp.md) |
| User requests push or CI deployment | [Git/CI](references/git.md) |

## Shared rules

- Work in the exact authenticated project root. Run ordinary CLI commands with
  `--non-interactive` for structured output and no prompts. Discover unfamiliar
  syntax with `shipd <command> --help --json`; load only that command's help.
  Installed help and returned schemas take precedence over examples here.
- Keep the user's Compose intent and existing files. Inspect before asking;
  plan before deploying changed source. Existing user authorization carries
  forward; a skill does not grant additional permissions.
- Never ask for tokens or secret values in chat, read credential files, or print
  secret environment values. Humans enter credentials in the hidden `shipd auth`
  terminal prompt or secrets on Shipd's returned action page.
- Preserve the server-returned operation ID. A retry continues that operation;
  changed source requires a new one. Do not turn a status request into a deploy.
- A completed apply is not proof of a live website. Report the returned public
  verification evidence and URL; never invent a hostname or a successful check.
