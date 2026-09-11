# Data and secret bindings

Read only when the app requires persistent data, managed PostgreSQL, or secrets.
These settings belong in the deploy override; preserve local Compose behavior.

`x-secret-env` maps environment names to secret references, never literal values:

```yaml
services:
  web:
    x-secret-env:
      DATABASE_URL: db.url
      STRIPE_KEY: stripe_key
  db:
    x-managed: postgres
secrets:
  stripe_key:
    external: true
```

This extends an existing local `db` PostgreSQL service. `db.url` is its managed
output; `stripe_key` is an external secret slot. Add only the dependencies the app
uses. Do not read existing secret values to author these bindings.

**What happens when a bound slot has no value.** `deploy` does not apply. It
returns `action_required` with one `secret_value` action per unfilled slot,
each carrying a URL and a verification code, and creates nothing — so nothing
is billed and nothing serves errors. Give the human the URL, wait for them to
enter the value, then run the same `deploy` again; it proceeds once every bound
slot is filled. A slot that is declared but not bound by any `x-secret-env`
never blocks a deploy.

You cannot read, set, or verify the value itself, and there is no command that
takes one — the value goes from the human's browser to the platform and is
injected into the container out of band. `deploy` will tell you whether a slot
is filled, never what it holds. Rotating a value on the same page restarts the
services that read it.

**Removing a slot destroys its value.** Deleting a slot from the Compose file is
a destructive plan step: it needs confirmation, and once applied the stored value
is gone everywhere and cannot be recovered — a human must enter a new one to use
that slot again. Do not remove a slot to "reset" it; rotate it on the action page
instead.

Named volumes use `x-storage: persistent`, `object`, or `ephemeral`. Databases and
SQLite need the required durability/locking semantics; do not move them onto
object storage to avoid a warning. Account for migrations and backups before
changing stored data. Never publicly expose a database just to connect the app.

For any returned human action, use the actions route in SKILL.md. Do not add
a database, storage service, or secret slot unless the application needs it.
