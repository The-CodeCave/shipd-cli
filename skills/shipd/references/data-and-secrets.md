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

**Schema migrations.** A managed PostgreSQL service also outputs
`db.migration_url`, a URL for its migration role: it creates and owns the app's
tables and may create schemas in its own database. `db.url` and its parts only
read and write rows; bind them on long-running services such as `api` and
`worker`. Bind `migration_url` only on a cron service with
`x-schedule: "manual"`, whose base Compose entry has the app's image and
`command:` set to the migration command:

```yaml
services:
  db:
    x-managed: postgres
  api:
    x-public: true
    x-secret-env: { DATABASE_URL: db.url }
  worker:
    x-secret-env: { DATABASE_URL: db.url }
  migrate:
    x-schedule: "manual"
    x-secret-env: { DATABASE_URL: db.migration_url }
```

`shipd run migrate` runs that command; `docker compose run migrate` does
locally. `shipd run` starts from the image of the last healthy deploy, so ship a
schema change in two steps: deploy the image with the migration and code that
works on both the old and the new schema (add first, remove later), run
`shipd run migrate`, then deploy code that needs only the new schema. On the
first deploy, the app must become healthy before its tables exist.
`shipd run migrate -- <cmd>` (e.g. `-- node dist/migrate.js`) runs any command
with the DDL credential; pass only the migration. Never migrate from a
long-running service's start command: the DDL credential must not live there.

A `manual` cron never runs on its own (its CronJob is suspended); `shipd run`
is its only trigger. Any cron may be `manual`, for any on-demand job. The
command should still be safe to repeat (take a lock, do nothing when the
schema is current) and must exit; the role allows 5 connections. A cron that
binds `migration_url` with any other schedule, including a date like
`0 4 29 2 *`, is refused with `MIGRATION_CRON_REQUIRES_MANUAL`, and a
`depends_on` on a `manual` cron is refused because it would never be met.

Binding `migration_url` on a long-running or `x-public` service is refused with
`MANAGED_OUTPUT_REQUIRES_CRON` at that `x-secret-env` line; an `x-managed: s3`
service has no such output (`MANAGED_OUTPUT_NOT_SUPPORTED_BY_ENGINE`). Shipd
puts the credential only into cron containers, which no route reaches; never
copy it elsewhere. Also not supported: `depends_on` with
`service_completed_successfully` (refused; the run is a separate step),
`migrate` behind `profiles:` (never deployed), or `migrate` without `image` or
`build`. `shipd run` output redacts the URL and its password, but not a
re-encoded form such as base64; never print it.

Named volumes use `x-storage: persistent`, `object`, or `ephemeral`. Databases and
SQLite need the required durability/locking semantics; do not move them onto
object storage to avoid a warning. Account for migrations and backups before
changing stored data. Never publicly expose a database just to connect the app.

For any returned human action, use the actions route in SKILL.md. Do not add
a database, storage service, or secret slot unless the application needs it.
To read or change the objects inside an `x-managed: s3` bucket, use the objects
route in SKILL.md.
