# Credential-scan false positives

Read when a `LEAKED_CREDENTIAL` diagnostic may be a false positive, or when a
declared exception needs review. `SNAPSHOT_REFUSED` alone is not evidence of a
false positive: known Shipd credentials also produce that refusal and cannot
be excepted.

## Review the finding and declare only the exact exception

1. Inspect the returned diagnostic: `grounding.file`, `grounding.line`,
   `fingerprint`, and `fix`. Local MCP `validate` or
   `shipd validate --non-interactive` supplies these before upload. `plan` also
   runs preflight; Docker is not needed to obtain credential findings. Do not
   compute a fingerprint yourself or infer it from the filename or line number.
2. Determine whether this is a real credential or benign source/test data.
   Explain the evidence to the user without quoting credential values. If it is
   real or uncertain, remove the literal and use Shipd's secret handoff, or
   exclude a private file that the build does not need. Do not create an
   exception merely because deployment is blocked.
3. For a verified false positive, discuss it with the user and, with their
   agreement, append to `compose.safety.yaml` at the project root. Preserve
   existing exceptions. Each entry has exactly `path`, `finding`, and `reason`:

   ```yaml
   x-safety:
     exceptions:
       - path: src/provider-labels.ts
         finding: "<copy the diagnostic.fingerprint verbatim>"
         reason: "Translation label for the provider form; contains no credential."
   ```

   Replace the example path and fingerprint with the reported values and give
   the actual reason. Never put a credential value in the file or reason.
   Shipd automatically loads this overlay after the base Compose file and
   `compose.deploy.yaml`; no extra flag, env file, or custom ignore list is
   needed. Keep it in the upload and version it: neither `.gitignore` nor
   `.dockerignore` may exclude it. It accepts only `x-safety.exceptions`, not
   service/runtime overrides, wildcards, or global scanner suppression.

## Obtain approval and continue

Run local MCP `plan` or `shipd plan --non-interactive`. Shipd requests human
review before uploading excepted source. Show the actual returned action URL
and let the human approve it there. Conversation agreement permits editing the
entry; it does not replace Shipd's confirmation. Never approve it on the user's
behalf or treat expiry/decline as consent.

MCP clients with URL elicitation receive that handoff; without it, JSON-RPC
error `-32042` contains `data.elicitations` with the URL and confirmation ID.
After approval, rerun `plan` and then the authorized `apply`/`deploy` from the
same folder. A review before upload has no uploaded operation for
`operations_resume` to continue. If source was already uploaded and a managed
operation is awaiting action, follow its returned resume instructions instead.

`validate` stays offline: `AUTHORIZATION_MISMATCH` with
`SAFETY_EXCEPTION_REVIEW_REQUIRED` describes an unverified local declaration,
even after server approval. Continue with online `plan`; do not repeatedly
validate or keep rewriting the entry to make that warning disappear.

`SAFETY_EXCEPTION_APPLIED` records an applied approval;
`SAFETY_EXCEPTION_STALE` means the entry no longer matches a current finding.
Review/remove stale entries instead of broadening them. Approval covers the
exact finding, path and reason for the same project and initiating identity.
Moving lines preserves it; editing an offending line, its path or reason needs
new review. PEM findings bind the whole file. Removing the entry disables its
use; restoring the identical entry can reuse its existing approval.

Hosted MCP cannot inspect or upload a local checkout. Use the folder CLI or
local stdio MCP for this workflow. If the installed version supplies no
fingerprint or rejects this overlay, check its help/version and report the
missing support; do not invent an exemption flag or bypass the scanner.
