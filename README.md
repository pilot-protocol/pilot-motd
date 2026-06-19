# pilot-motd

> ## ⚠️ Deprecated — MOTD moved to [`pilot-changelog`](https://github.com/TeoSlayer/pilot-changelog)
>
> The message-of-the-day banner now rides the changelog's render pipeline as
> the `scope: motd` feed. Publish/clear banners there with
> `scripts/set-motd.sh` / `scripts/clear-motd.sh`; the daemon polls
> `https://raw.githubusercontent.com/TeoSlayer/pilot-changelog/main/feed-motd.json`.
> This repo is retained only for historical reference and is no longer the
> source `pilot-daemon` reads (as of the daemon release that flips the default
> feed URL). See `SCHEMA.md` in pilot-changelog.

Source of truth for the Pilot Protocol **message of the day (MOTD)** — a short
notice shown ahead of every `pilotctl` command for one UTC calendar day at a
time. Used for network-wide announcements: maintenance windows, incident
updates, breaking-change heads-ups.

The whole "database" is one file: [`motd.json`](./motd.json). Each `pilot-daemon`
polls it on an interval, picks the entry dated for the current UTC day, and
mirrors it locally; `pilotctl` then prepends it:

```
$ pilotctl info
Message of the day: overlay maintenance 22:00 UTC — expect ~5min blips

<normal pilotctl info output>
```

The daemon fetches the raw file from this repo's default branch:

```
https://raw.githubusercontent.com/pilot-protocol/pilot-motd/main/motd.json
```

So **committing to `main` is the entire publish workflow** — every daemon
picks the change up on its next poll (GitHub's raw CDN cache is a few minutes).

## Posting a message

Use the helper (defaults to today, UTC), then commit:

```bash
scripts/set-motd.sh "overlay maintenance 22:00 UTC — expect ~5min blips"
# schedule ahead for a specific UTC day:
scripts/set-motd.sh "v2 cutover — see #ops" 2026-07-01

git add motd.json && git commit -m "motd: maintenance notice" && git push
```

## Clearing a message

Clearing is first-class — **an empty MOTD is a valid update.** Any of these
remove the banner within one poll interval:

```bash
scripts/clear-motd.sh             # clear today's (UTC) entry
scripts/clear-motd.sh 2026-07-01  # clear a specific day
scripts/clear-motd.sh --all       # remove every entry
```

…then commit `motd.json`.

## Rules

- `date` is a **UTC** calendar day, `YYYY-MM-DD`. A message is active only on
  that day; future-dated entries wait their turn.
- Keep at most one entry per day. If several share a day, the daemon takes the
  first non-blank one.
- Keep messages short and plain-text — they print in a terminal.

See [`SCHEMA.md`](./SCHEMA.md) for the exact contract.
