---
name: shipd
description: Deploy and operate apps on Shipd through its CLI or MCP. Covers CLI installation, project connection, organisations and access, deployment, approvals, credential-scan exceptions, diagnosis, and bucket objects. Not for developing Shipd itself or deploying to other clouds.
---

# Shipd

Shipd is a managed cloud operated by the user's coding agent. Standard
`compose.yaml` plus `compose.deploy.yaml` describe the app; Shipd builds and runs
it remotely. The dashboard manages personal and organisation projects and human
actions. Publishing uses a project token bound to the application's folder.

## Load only the current task

Read **one** reference for the immediate task; load another only as needed.
Do not preload this directory or copy the skill into AGENTS.md, CLAUDE.md, or
memory. Retain only project folder, operation ID, state, and next action.
If `shipd` is missing, start with connect to install it, then continue the task.

| Immediate need | Read |
|---|---|
| Missing CLI, authentication, or wrong folder | [connect](references/connect.md) |
| Personal/org ownership, roles, invitations, billing, or transfers | [organisations](references/organisations.md) |
| First publish, changed source, or interrupted deployment | [deploy](references/deploy.md) |
| Create or repair Compose and public HTTP exposure | [compose](references/compose.md) |
| Connect a custom domain or check DNS/TLS publication | [domains](references/domains.md) |
| `action_required`, pending approval, or secret entry | [actions](references/actions.md) |
| `LEAKED_CREDENTIAL` or a suspected scanner false positive | [safety exceptions](references/safety-exceptions.md) |
| Inspect health or investigate a failed public check | [diagnose](references/diagnose.md) |
| App needs persistent data, PostgreSQL or secret bindings | [data and secrets](references/data-and-secrets.md) |
| User requests MCP or the client needs a connection | [MCP](references/mcp.md) |
| User requests push or CI deployment | [Git/CI](references/git.md) |
| Read, upload or delete bucket objects; run `aws s3` on a bucket | [objects](references/objects.md) |

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
- For a verified scanner false positive, use the reviewed exception workflow in
  optional `compose.safety.yaml`. Discuss the finding with the user before adding
  an entry; the file itself does not grant approval or disable credential checks.
- Preserve the server-returned operation ID. A retry continues that operation;
  changed source requires a new one. Do not turn a status request into a deploy.
- A completed apply is not proof of a live website. Report the returned public
  verification evidence and URL; never invent a hostname or a successful check.
