# Inspect and diagnose

Read for a health question, a failed deployment, or a public URL that did not pass.

Run `shipd status --non-interactive` in the authenticated root. Inspect the rollup,
coverage/staleness, incidents, public endpoint outcomes, and grounded file/service/
key/line information. A `NO_DEPLOY` response is expected before the first apply;
it does not mean a broken login. Never deploy merely to answer a health question.

For a known operation, `shipd operations resume <operation_id> --non-interactive`
inspects **and can continue** managed work. Use it only when continuing that work
is authorized, not as an unconditional read-only probe. Keep the actual returned
operation identifier even if the original terminal is gone.

Read only source/config implicated by the evidence. A non-null diagnosis and
suggested fix are evidence to evaluate against the app; `diagnosis: null` means
Shipd has no established cause. Explain the reduced raw signal and uncertainty.
Never invent a cause or replace a missing estimate/observation with zero.

For public verification failures:

| Evidence | Interpretation and next step |
|---|---|
| DNS unresolved / TLS pending or failed | Apply may be complete. Inspect the exact failure and recheck that operation after a relevant change or bounded wait. |
| HTTP 4xx/5xx, redirect loop, broken critical assets | Inspect the relevant application route/config/build output; use status for diagnosis before editing. |
| Verification timeout or interrupted response | Verification did not pass. Retain the deployed operation and recheck; don't label the URL live. |
| No public HTTP endpoints | Confirm whether a private service was intended. A website needs a declared web port and public exposure. |

If no `publication` evidence is available, state that verification is unavailable.
Do not promote `result.endpoints` (configured URLs) to verified URLs. Public
checks are bounded network evidence, not browser execution or a guarantee of
every feature.

For a requested repair, make the smallest evidence-supported change, then plan
and deploy **new source with a new operation**. An old approval does not authorize
changed content. If the same failure repeats without new evidence, report the
blocker with its ID and next needed action rather than looping indefinitely.

Additional operations: discover `shipd events --help --json` for post-deploy
notifications or `shipd export --help --json` when source recovery is requested.
Export writes files, so use an intended output directory. Do not invent `shipd
logs`, `shipd rollback`, or other commands absent from installed help.
