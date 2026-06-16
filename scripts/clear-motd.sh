#!/usr/bin/env bash
# Clear the message of the day, then review + commit motd.json.
#
# Usage:
#   scripts/clear-motd.sh             # clear today's (UTC) entry
#   scripts/clear-motd.sh 2026-07-01  # clear a specific UTC day
#   scripts/clear-motd.sh --all       # remove every entry
#
# Does not commit — review the diff and commit motd.json yourself.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARG="${1:-$(date -u +%Y-%m-%d)}"

if [[ "$ARG" != "--all" ]] && ! [[ "$ARG" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "error: argument must be YYYY-MM-DD or --all (got: $ARG)" >&2
  exit 2
fi

python3 - "$ROOT/motd.json" "$ARG" <<'PY'
import json, sys
path, arg = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        feed = json.load(f)
except FileNotFoundError:
    feed = {"schema_version": 1, "messages": []}
feed["schema_version"] = feed.get("schema_version", 1)
if arg == "--all":
    feed["messages"] = []
    print("cleared all motd entries")
else:
    feed["messages"] = [m for m in feed.get("messages", []) if m.get("date") != arg]
    print(f"cleared motd for {arg}")
with open(path, "w") as f:
    json.dump(feed, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("review the diff, then: git add motd.json && git commit && git push")
PY
