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
