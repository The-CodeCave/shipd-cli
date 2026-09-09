# Publish or resume

Read for a new publish, changed source, or a known deployment operation.

## Resume first when an operation already exists

Use `shipd operations resume <operation_id> --non-interactive` with the
**server-returned** ID. For managed local operations (`local-…`), this continues
the immutable uploaded source after approval or disconnection; a completed apply
is rechecked without deploying it again. Follow returned retry instructions for
other operation kinds. Never start a fresh deploy merely because the terminal
disconnected.

If the upload itself was interrupted, retry the same command with
`shipd deploy --operation <operation_id> --non-interactive` (or `shipd plan` for a
plan upload), from unchanged files. A source mismatch needs a new operation.
If the original create response was lost, reuse the submitted ID until the server
returns its canonical ID. Do not reuse a **plan** operation ID for **apply**.

## New or changed source

1. Run `shipd doctor --non-interactive`. Inspect detected framework, commands,
   port/bind address, environment **names**, persistent data, and grounded findings.
   Doctor inspects; it does not write Compose, fix the app, or configure the agent.
   Read only the implicated source/configuration. If Compose needs changes, select
   the compose reference from the skill's routing table.
2. Prepare the app and Compose for a production start. Preserve local behavior,
   required persistence and migrations. Use ignore rules to exclude credentials,
   dependencies and generated output while retaining files needed to build.
3. Run `shipd plan --non-interactive`. It uploads and validates remotely. Local
   `shipd validate` requires Docker Compose and is optional; do not make installing
   Docker a prerequisite. Read the actual plan, safety/admission findings, and cost
   evidence. Explain services, meaningful changes and any human action in plain
   language. Report unavailable estimates as unavailable.
4. If deployment is authorized and the plan is acceptable, run
   `shipd deploy --non-interactive`. This is the `apply` alias. Do not use force
   flags, fake credentials, or weakened safety rules to get past a blocker.

## Interpret the result

Managed output is **JSON Lines**: state changes followed by a final result. Do not
parse the entire stream as one JSON object or treat the first line as completion.
Use `schema`, `state`, `status`, nested `result`, and the operation ID together;
exit code 2 can mean a still-pending deployment or a usage error.

| Result | Next action |
|---|---|
| `uploading`, `queued`, `running` | Keep the command running, or retain the ID and resume. A timeout does not cancel work. |
| `awaiting_action` / `action_required` (exit 3) | Select the actions reference; use the actual returned actions. |
| `failed` (exit 1) | Inspect the reported failure; use diagnosis when needed. Retry the same source/operation only where supported. |
| `succeeded` + `publication.status: verified` | Return `publication.verified_urls` and the observed outcome. |
| `succeeded` + `publication.status: failed` (exit 1) | Apply completed. Inspect check failures and recheck with resume; don't blindly redeploy. |
| `no_public_http_endpoints` or no publication evidence | Do not announce a live website. Private services can be intentional; a requested website needs public HTTP exposure and verification. |

Public verification checks DNS/TLS, HTTP, redirects and bounded same-origin
critical assets. It runs **after apply**, not before traffic changes, and does
not execute the application in a browser. It is not proof that every app feature
works. A missing `publication` field on an older version is not a passing check.

Avoid endless retries. After the same failure recurs without new evidence, retain
the ID and report the specific blocker. Continue only after a relevant change or
within a bounded wait supported by the command.
