# Custom domains (`x-domains`)

Add the hostname to `x-domains`, retain the declared ingress port, and run
`shipd validate` then `shipd plan --non-interactive` from the project folder.
A successful plan may still report `blocked_by_admission`: DNS ownership and
routing must be verified before Shipd publishes the domain.

## DNS for an exact subdomain

Obtain this project's `domain_connect_target` from its DomainConnect action.
Use that exact project-specific target, not the generic `connect.shipd.cloud`
or another project's target.

At your DNS provider, replace the subdomain's unrelated A/AAAA records with:

| Type | Name | Value |
| --- | --- | --- |
| CNAME | requested subdomain | returned `domain_connect_target` |

Keep the record DNS-only during verification (no proxy or CNAME flattening).
This direct CNAME proves project ownership and routes traffic. No TXT record is
required for this exact-subdomain flow. Do not leave a conflicting A/AAAA record.

If a direct CNAME is unavailable, ownership can instead be proved with a CNAME
at `_shipd-challenge.<hostname>` to the same project target. Separately point the
hostname's A/AAAA/ALIAS to the platform addresses returned for that target;
ownership alone does not satisfy routing. Do not copy IPs from another cell.
Wildcard domains use a separate `_acme-challenge` delegation action; do not apply
the exact-subdomain recipe to a wildcard.

After public DNS propagation, complete the DomainConnect action. Re-run plan;
then apply and inspect the returned domain/certificate state. HTTPS publication
waits for certificate readiness. The platform URL can remain enabled throughout.

## CLI and MCP workflow

```sh
shipd domains connect nimbus.ek3r7jer1e.xyz
# Set the DNS records printed in the action, then open its exact URL.
shipd domains status
shipd plan --non-interactive
shipd apply --non-interactive
```

`connect` returns `action_required` (exit 3) while DNS needs verification. The
message names each DNS record; its capability-bearing action URL opens the
verification page. If DNS has not propagated, approval refuses and the same
page remains pending: correct DNS and retry there. No secret/token belongs in
DNS. After approval, `domains status` reports the registry claim as `verified`.
This means domain ownership/routing passed; certificate issuance and HTTPS
publication still belong to plan/apply.

The equivalent MCP tools are `domains_connect` with a `hostname` argument and
`domains_status` with no arguments. Connect is a mutation; status only reads.
A repeated connect on an already verified claim returns its state. A new connect
on a pending domain can issue a fresh action if its previous link was lost or
expired. Claim exclusivity is enforced by the control plane.

The old Homebrew 0.1.6 binary exposes only `domains release`; use the updated
binary containing connect/status. Do not infer command support from an old
admission hint alone.

## Certificate pending after apply

The current apply completes after requesting a certificate; it does not wait
for issuance or automatically publish the withheld HTTPS route afterwards.
`certificate_pending` therefore is not a live custom-domain URL, and that host
may return 404 while only the platform URL is routed. Once issuance has finished,
run `shipd plan` and `shipd apply` again to publish the route. Confirm the custom
hostname appears as published and verify its HTTPS response. Resuming a completed
operation only rechecks its recorded endpoints; it does not render a new route.
