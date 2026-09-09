# Complete human actions

Read when an operation returns `action_required` or a pending confirmation.

1. Preserve the outer managed payload's operation ID and every returned action.
   Actions live inside its `result`, which can have a different nested operation
   ID. Resume managed deployment with the outer ID, not that nested ID. Use the returned fields;
   different command versions can expose different envelope schemas.
2. Explain each action's purpose and consequence. Open or show its exact `url`
   through the client's supported navigation flow. Check the host against the
   configured Shipd installation and display it. A returned action page handles
   secrets, billing, provider authorization or approval; never invent its URL or
   ask the user to navigate through settings.
3. Secret/password/payment values belong on that page and never in agent chat,
   terminal arguments, tool arguments, logs, or saved project files. A verification
   code, if this surface returns one, identifies the action; it is not a credential.
   Never claim a missing code or fabricate one.
4. Use `shipd confirmations watch <confirmation_id> --timeout 5m --non-interactive`
   if a bounded watcher fits the harness. Otherwise use
   `shipd confirmations status <confirmation_id> --non-interactive` when resuming.
   Expiry/timeout is not approval. Avoid tight repeated polling.
5. On approval, managed local deployments continue with
   `shipd operations resume <operation_id> --non-interactive`. Other operations
   follow their returned retry hint or command-specific help (for example, Git
   binding uses its confirmation ID). Resume the exact requested action, not a
   fresh deploy of possibly changed files.

`declined`, `cancelled`, `expired`, and `failed` are terminal outcomes. Do not
reopen the same request automatically or treat it as consent. Explain what
stopped the operation; a fresh request needs relevant user intent. If multiple
independent actions remain, keep them visible instead of silently completing
only the first.

An MCP client with URL elicitation may carry the same human handoff. Elicitation
completion is a signal to check/resume the operation, not permission for unrelated
effects. If URL elicitation is unavailable, show the provided action and retain
its IDs for the next turn.

The user's prior deployment request already authorizes ordinary preparation and
deployment within its scope. Do not add a generic approval ceremony before every
command. Shipd's explicit cost, destructive-change, and secret boundaries still
apply to the exact operation returned.
