#!/usr/bin/env bash
# Set the message of the day, then review + commit motd.json.
#
# Usage:
#   scripts/set-motd.sh "Your message"              # today (UTC)
#   scripts/set-motd.sh "Your message" 2026-07-01   # a specific UTC day
#
# Replaces any existing entry for that date. Does not commit — review the
# diff and commit motd.json yourself.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MSG="${1:?usage: set-motd.sh \"message\" [YYYY-MM-DD]}"
DATE="${2:-$(date -u +%Y-%m-%d)}"

if ! [[ "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "error: date must be YYYY-MM-DD (got: $DATE)" >&2
  exit 2
fi

python3 - "$ROOT/motd.json" "$DATE" "$MSG" <<'PY'
import json, sys
path, date, text = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(path) as f:
        feed = json.load(f)
except FileNotFoundError:
    feed = {"schema_version": 1, "messages": []}
feed["schema_version"] = feed.get("schema_version", 1)
msgs = [m for m in feed.get("messages", []) if m.get("date") != date]
msgs.append({"date": date, "text": text})
msgs.sort(key=lambda m: m.get("date", ""))
feed["messages"] = msgs
with open(path, "w") as f:
    json.dump(feed, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(f"set motd for {date}: {text}")
print("review the diff, then: git add motd.json && git commit && git push")
PY
