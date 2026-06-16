# MOTD feed schema

`motd.json` is the only published artifact. It is consumed by `pilot-daemon`
(`internal/motd` in the [pilotprotocol](https://github.com/TeoSlayer/pilotprotocol)
repo).

## Shape

```json
{
  "schema_version": 1,
  "messages": [
    { "date": "2026-06-15", "text": "overlay maintenance 22:00 UTC", "id": "maint-0615" }
  ]
}
```

### Top level

| Field | Type | Notes |
|-------|------|-------|
| `schema_version` | int | Must be `1`. May be omitted (treated as compatible). A different non-zero value is rejected by the daemon, which then keeps its last mirror. |
| `messages` | array | Zero or more entries. An empty array means "no message" — a valid, intentional state. |

### Message entry

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `date` | string | yes | UTC calendar day, `YYYY-MM-DD`. The message is active only on this day. |
| `text` | string | yes | The banner text. Blank/whitespace counts as no message. Keep it short and plain-text. |
| `id` | string | no | Optional opaque identifier for your own bookkeeping; ignored by the daemon. |

## Semantics

- **Selection:** the daemon picks the first entry whose `date` equals the
  current UTC day and whose `text` is non-blank. There should be at most one
  entry per day.
- **Clearing:** removing today's entry, blanking its `text`, or publishing
  `{"schema_version":1,"messages":[]}` all clear the banner. Committing an
  empty MOTD updates the value exactly like posting one.
- **UTC only:** day boundaries are UTC. `pilotctl` re-checks the day when it
  reads its local mirror, so a message never lingers past its UTC day even if a
  daemon was offline across midnight.
- **Forward-dating:** entries dated in the future are ignored until their day
  arrives, so you can stage announcements ahead of time.

## Size & safety

- The daemon reads at most 64 KiB of the feed. Keep the file small.
- Non-2xx responses and parse errors are non-fatal: the daemon logs at debug
  level and keeps its last good mirror.

## Versioning

Breaking changes bump `schema_version`. Daemons reject feeds whose declared
version they don't understand (rather than mis-parsing), so a version bump is
a deliberate, coordinated rollout.
