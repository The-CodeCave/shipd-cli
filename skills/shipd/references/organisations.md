# Organisations, ownership, and access

Read for personal/org context, membership, permissions, billing, or a project
transfer. Use the user's configured dashboard (officially
[app.shipd.cloud](https://app.shipd.cloud)). These are dashboard workflows;
the CLI operates one connected project. Do not invent `shipd org`, project-list,
invitation, or transfer commands. Check installed help for any newer surface.

## Choose the right owner and project

- A project belongs to a personal account or an organisation. The owner's plan,
  resource limits, and billing apply. An organisation has its own billing context;
  a member's personal plan is not its plan.
- The dashboard owner selector offers **Personal**, joined organisations, and
  **Shared with me** for direct project access. Selecting one filters the view;
  it neither transfers a project nor changes a CLI folder's authentication.
- Check the project's recorded owner and target environment before creating a
  project, issuing a token, or changing resources. A display name alone does not
  identify the right project. Losing membership can return the dashboard to
  Personal; that does not mean organisation projects were deleted.
- Each CLI connection remains bound to its exact local folder and project token.
  `SHIPD_TOKEN`, if present, overrides that stored credential. Organisation
  membership by itself does not connect a folder or widen a token's scopes.

## Roles and inherited access

| Organisation role | Useful consequence |
|---|---|
| `owner` | Full project capabilities and organisation governance; the last owner cannot leave or be removed/demoted. |
| `admin` | Full project capabilities, org member/invitation management, settings and billing; cannot edit owners or promote someone to owner. |
| `developer` | View, manage environments, deploy, and browse/write objects, subject to restrictions. |
| `viewer` | Read project state; no deploy or object-content access by default. |

Organisation membership supplies inherited access across its projects. A direct
project grant can instead give a guest access to that project without org
membership, org billing, or member administration. When an org member also has a
direct project row, their org role takes precedence; direct extra grants do not
raise it, while applicable revocations can restrict developers/viewers.

Production protection withholds deployment and object-data/bucket/key operations
from roles below admin, including developers. Token presets and scopes can narrow
access further. On a permission refusal, check current membership, environment
protection, and token scopes; have an authorised owner/admin resolve the missing
access. Do not repeatedly log in, request someone else's token, or disable
production protection just to make a command work.

## Human dashboard workflows

Use these routes on the selected dashboard host with the actual org ID:

- `/orgs/new`: create an organisation when requested. Select it when creating
  its projects; switching owners does not move existing projects.
- `/orgs/<orgId>/settings`: rename, leave, or archive. Only an owner archives an
  empty organisation; preserve the last-owner rule.
- `/orgs/<orgId>/members` and `/orgs/<orgId>/invites`: owner/admin member controls
  and invitations. Invite roles are admin/developer/viewer; the recipient signs
  in with the invited email and explicitly accepts. Signup alone does not join.
  Invitation links are private handoffs, not source files or diagnostic content.
- `/orgs/<orgId>/billing`: owner/admin billing and effective limits. Report the
  returned limits and estimates; a plan label is not measured physical capacity.

Role reduction, removal, or leaving can retire that human's project tokens and
other credentials. Retirement can remain pending while capabilities drain; keep
the same returned operation ID on retry and report completion only when shown.
Reconnect with a newly authorised token if the old one has been retired.

## Moving an existing project

Use the project's transfer flow and `/transfers` for progress. A source personal
owner or org owner proposes; the destination personal owner or org owner/admin
approves. Both sides approve the exact transfer terms before work begins.

The project keeps its IDs, data, and running workloads. The transfer retires old
project tokens, CLI/MCP logins and object keys, cancels open approvals/invites,
and stops Git automation pending reapproval. It can wait for credential drain
and destination limits. `converging` means ownership moved but remaining effects
are still being confirmed; it is not complete.

Preserve the transfer ID and let the existing transfer continue. Do not redeploy
or create a replacement project to move ownership. Afterward, authorised humans
issue new credentials, reconnect folders, and reapprove Git bindings as needed.
Stopping a transfer after revocation does not restore the revoked credentials.
