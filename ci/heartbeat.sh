#!/usr/bin/env sh
# Run a command that goes quiet for minutes at a time, printing a line every
# 30s so the step never stops emitting output.
#
#   ci/heartbeat.sh <label> <command> [args...]
#
# A silent step is not just unpleasant to watch: an idle log stream can be
# dropped between the agent and the server, and the step is then recorded as
# failed (exit 255) even though its pod succeeded. The command's own output is
# kept aside and shown on failure.

set -eu

label="$1"
shift

out=$(mktemp -t heartbeat.XXXXXX.log)

"$@" >"$out" 2>&1 &
pid=$!

elapsed=0
while kill -0 "$pid" 2>/dev/null; do
  sleep 30
  kill -0 "$pid" 2>/dev/null || break
  elapsed=$((elapsed + 30))
  printf '  ... %s, %dm%02ds elapsed\n' "$label" "$((elapsed / 60))" "$((elapsed % 60))"
done

status=0
wait "$pid" || status=$?

if [ "$status" -ne 0 ]; then
  echo "$label failed (exit $status):" >&2
  tail -60 "$out" >&2
else
  tail -5 "$out"
fi

rm -f "$out"
exit "$status"
