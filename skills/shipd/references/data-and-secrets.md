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
uses. Shipd's apply flow asks the human to fill missing slots on a direct action
page. Do not read existing secret values to author these bindings.

Named volumes use `x-storage: persistent`, `object`, or `ephemeral`. Databases and
SQLite need the required durability/locking semantics; do not move them onto
object storage to avoid a warning. Account for migrations and backups before
changing stored data. Never publicly expose a database just to connect the app.

For any returned human action, use the actions route in SKILL.md. Do not add
a database, storage service, or secret slot unless the application needs it.
