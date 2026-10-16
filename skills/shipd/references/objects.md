# Objects in managed buckets

Read only to list, read, upload or delete objects in a service declared
`x-managed: s3`, or to run the AWS CLI or an S3 SDK against those buckets.
Creating, deleting or resizing a bucket is a Compose change (`x-managed`,
`x-size`) that goes through plan and apply, never through these commands.
Buckets of `x-storage: object` volumes are not reachable here.

A bucket is addressed by its Compose service name: `s3://uploads/path/key`.
The real `sb-…` name works too; `aws` output may show it, and
`shipd s3 buckets` shows the mapping.

## Native commands

Run each with `--non-interactive` for versioned JSON; check syntax with
`shipd s3 <command> --help --json`. Reads need `objects_read`, uploads, copies
and deletes `objects_write` too.

- `shipd s3 buckets`: every `x-managed: s3` service in declared order with its
  `state`; `bucket` only when `ready`. Uses no credential.
- `shipd s3 ls s3://uploads/photos/`: one page of objects and folders;
  `--recursive` for every key below the prefix, `--max-items <n>` (1–1000).
  If `next_token` is present, continue with `--starting-token <next_token>`.
- `shipd s3 cp <source> <destination>`: each side a local path or
  `s3://<service>/<key>`; a trailing `/` keeps the source's name. `--recursive`
  for a directory or prefix, `--dryrun` to list without transferring,
  `--content-type <type>` for uploads and copies. `-` reads stdin (one object,
  up to 8 MiB); `-` as destination is human output only
  (`S3_STDOUT_TARGET_IN_JSON_MODE` under JSON). Symlinks are never followed; a
  key that would land outside the destination is skipped. Past 8 MiB an upload
  is multipart; a failed one is aborted, and `leftover_uploads` names any that
  could not be.
- `shipd s3 rm s3://uploads/key`, or a prefix with `--recursive`. Run with
  `--dryrun`, read the preview, then rerun without it. Emptying a whole bucket
  (`shipd s3 rm s3://uploads/ --recursive`) also needs `--all`.

A partial failure exits 1 and still prints the payload: read `failed` and
`skipped` (`cp`) or `errors` (`rm`).

**Deletes and overwrites are immediate.** `rm`, an overwriting `cp` and
`exec --write` ask no human and cannot be undone. Every grant is audited and
listed for the owner in the dashboard. Change only what the user asked for.

## Anything else: `shipd s3 exec`

`shipd s3 exec [--write] [--bucket <service>]... -- <program> [args...]` runs an
unmodified AWS CLI or SDK program against a local proxy inside `shipd`; the
proxy holds the real credentials and lives exactly as long as the program.

    shipd s3 exec -- aws s3 ls s3://uploads/
    shipd s3 exec --write -- aws s3 sync ./public s3://assets/ --delete
    shipd s3 exec --write --bucket uploads -- python scripts/seed.py

- Read-only unless `--write` comes before `--`; `--bucket` narrows the grant.
- The program gets a closed environment: `AWS_ENDPOINT_URL_S3` at the proxy, a
  stand-in key valid only there for that run, the region, a private AWS config,
  and `SHIPD_S3_BUCKETS` (the service names). Profile, session-token, role and
  other endpoint variables are removed.
- Do not pass `--endpoint-url`, `--profile` or keys to `aws`. Needs AWS CLI
  v2.13 or newer; an older one sends the stand-in key to AWS and gets
  `InvalidAccessKeyId`.
- Its stdout, stderr and exit code are the program's. Shipd adds only stderr
  lines `shipd s3: <CODE>: <sentence>` and a closing count of refused requests.
- It is not an MCP tool; run it from a shell in the project folder.

There is no `eval "$(shipd … env)"` or set-env form, by design: it would put
real credentials into your shell, history and transcripts, or need a detached
daemon. Never try to read, print, export or reuse S3 credentials, and never ask
the user for S3 keys. Shipd never shows them, so there is nothing to find.

## Credential lifetime

Each command takes a fresh grant valid 900 s (about 1–3 s to obtain). Long
transfers and `s3 exec` renew it before expiry. If renewal fails, the current
one serves until it expires; under `s3 exec` requests then fail with
`XShipdCredentialExpired`. Rerun the command. Revoking a token stops new grants
at once; issued ones live out their 900 s.

## Refusals

| Code | Do |
|---|---|
| `OBJECTS_SCOPE_MISSING` | Tokens issued before object access carry no object scope: ask the owner to re-issue the agent token, or run `shipd auth login` and approve the Full preset. If only writes are refused, the owner turned writes off for this project: tell the user |
| `OBJECT_NO_HEALTHY_DEPLOY` | Nothing healthy is deployed: deploy, then retry |
| `OBJECT_NO_MANAGED_BUCKETS`, `OBJECT_SERVICE_NOT_A_BUCKET`, `NoSuchBucket` | Use a name from `shipd s3 buckets`; buckets are declared in Compose |
| `OBJECT_BUCKET_NOT_READY`, `XShipdBucketNotReady` | Being created or deleted: check `shipd status`, retry after the deploy settles; if `buckets` still shows `absent` or `mismatch`, report it |
| `OBJECT_GRANT_RATE_LIMITED` | Wait `retry_after_seconds`, then retry |
| `OBJECT_GRANT_TOO_MANY_BUCKETS` | Address one bucket, or pass `--bucket` |
| `OBJECT_GRANT_TIMEOUT`, `OBJECT_GRANT_UNAVAILABLE`, `S3_ENDPOINT_UNREACHABLE` | Retry shortly; report it if it persists |
| `OBJECT_GRANT_REFUSED` | Report its code and correlation ID; do not work around it |
| `OBJECT_ENDPOINT_UNAVAILABLE` | Object access is not enabled for this project's cell yet; tell the user |
| `S3_REQUEST_FAILED` | Act on the S3 code and request ID it names; retry once |
| `S3_TRANSFER_TOO_MANY_ENTRIES` | Copy narrower prefixes, or use `aws s3 sync` under `shipd s3 exec` |
| `XShipdWriteNotGranted` | Add `--write` before `--` |
| other `XShipd…` | Shipd's proxy refused that request; its message names the fix |

## Hosted MCP

A hosted MCP connection offers only `s3_buckets` (names and readiness, no
credential). Listing, copying and deleting need the folder CLI or local stdio
MCP (`s3_buckets`, `s3_ls`, `s3_cp`, `s3_rm`).
