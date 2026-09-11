# MCP connections

Read only when the user requests MCP or the current client needs an MCP connection.
The ordinary folder CLI flow already works; integrations are not first-publish
prerequisites. Read only the matching section below.

## Local MCP

`shipd mcp` serves MCP over stdio. The client must launch it with its working
directory set to the exact authenticated project root. Reuse that connection;
do not paste tokens into MCP configuration or agent instructions.

Use the client's actual integration format, discovered from its documentation or
existing configuration. Do not assume every client supports a `cwd` key. Avoid
adding a global connection that points other projects at this folder's identity.

Discover available tools and use their schemas; don't copy the full tool catalog
into persistent context. Local MCP supports the shared plan/apply workflow.
Where the harness supports selective tool discovery, request only the relevant
Shipd tool. Shipd does not currently expose MCP documentation resources or prompts;
do not call invented `resources/read` URIs as a disclosure mechanism.

Local `validate`, `plan` and `apply` can report credential-scan false positives.
Use `grounding.file` and `fingerprint` from a `LEAKED_CREDENTIAL` diagnostic for
an exact, user-agreed `compose.safety.yaml` exception; select safety exceptions
from the skill's entry point for the workflow. `confirm_upload` only acknowledges
an undeclared upload scope and does not bypass credential checks. `plan` opens
the human review; if URL elicitation is unavailable, `-32042` returns
`data.elicitations`. After approval before upload, call `plan`/`apply` again from
the same folder. `operations_resume` requires an existing uploaded operation.

## Hosted MCP

Use the endpoint and permissions provided by the project's Setup page and the
client's credential entry flow. Hosted tools can inspect state and resume existing
operations when granted those permissions. They cannot read a local checkout or
upload/plan/apply its new source. Use the folder CLI or local stdio MCP for that.
Don't request a token in chat to configure a hosted connection.

## Mechanical diagnosis fixes (local stdio MCP)

Call `fix_preview` with `{"service":"web"}` after `status` supplies a
`suggested_fix`. Review the returned edit, then call `fix_apply` with
`{"service":"web","fix_id":"<digest from preview>"}`. The CLI equivalents are
`shipd fix preview web` and `shipd fix apply web <digest>`. The shared Rust API
uses `Command::FixPreview` / `Command::FixApply` with `execute`.

The digest binds the checkout path, project, deployed version, complete diagnosed
Compose source, and engine-selected edit. Callers cannot submit arbitrary edits.
Apply refuses changed source, symlinks, ambiguous fixes, or a different digest.
This authorizes a local file edit using the caller's filesystem access; deployment
approvals and project-token scopes are unchanged. Hosted MCP has no checkout and
classifies this verb as checkout-bound, like `plan`.

The result is `shipd.fix/v1`. Preview writes nothing. Apply atomically replaces
one Compose file and records a write-ahead audit in `.shipd-fix-audit.jsonl`
(project, service, deploy version, fix identity, hashes, timestamp, and state;
no source text). Retrying the same fix with identical resulting files is a no-op,
including recovery after the rename committed but the response was lost.
Keep the journal for retry evidence; exclude `.shipd-fix*` from version control
and deployment uploads. A crash may leave `.shipd-fix.lock` or `.shipd-fix.tmp`;
remove these only after checking no fix process is running. The lock serializes
Shipd fix writers; other editors must avoid concurrent writes during apply.

Apply reruns local validation, doctor, local plan, and deployed diagnosis, and
returns all four results (including failures or unavailable backends). It does
not upload or deploy the checkout. The exit status reflects validation failures;
`state: applied` still means the source edit committed. Runtime diagnosis continues
to describe the deployed version. Review the plan and run `shipd apply` separately,
then use `status` to observe recovery. In managed-only environments the local plan
may report its missing cluster backend; run the ordinary remote `shipd plan` next.
