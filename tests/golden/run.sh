#!/bin/bash

# Golden-file test for the log pipeline: the collector reads a fixed input.log,
# zeroes timestamps (see config.yaml), and writes OTLP JSON via the file
# exporter. Records are canonicalized with jq (batching-independent) and diffed
# against data/expected.jsonl.
#
# Usage: IMG=<collector image> ./run.sh [--record]
#   --record  re-record data/expected.jsonl instead of comparing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v jq &> /dev/null; then
    echo "This script requires 'jq'. Please install and try again."
    exit 1
fi
if [ -z "${IMG:-}" ]; then
    echo "IMG must be set to the collector image under test"
    exit 1
fi

RECORD=false
[ "${1:-}" = "--record" ] && RECORD=true

EXPECTED_LINES="$(wc -l < data/input.log | tr -d ' ')"

cleanup() {
    status=$?
    if [ "$status" -ne 0 ]; then
        docker compose logs collector 2>/dev/null | tail -40 || true
    fi
    MY_UID="$(id -u)" MY_GID="$(id -g)" docker compose down -v >/dev/null 2>&1 || true
    exit "$status"
}
trap cleanup EXIT

rm -f data/output.json
MY_UID="$(id -u)" MY_GID="$(id -g)" docker compose up -d

echo "Waiting for $EXPECTED_LINES log records ..."
for _ in $(seq 1 30); do
    count="$(jq -s '[.[].resourceLogs[].scopeLogs[].logRecords[]] | length' data/output.json 2>/dev/null || echo 0)"
    [ "$count" -ge "$EXPECTED_LINES" ] && break
    sleep 2
done
if [ "${count:-0}" -lt "$EXPECTED_LINES" ]; then
    echo "Timed out: got ${count:-0}/$EXPECTED_LINES log records"
    exit 1
fi

# Canonical form: one sorted-key JSON log record per line, independent of batching
jq -cS '.resourceLogs[].scopeLogs[].logRecords[]' data/output.json | sort > data/actual.jsonl

if [ "$RECORD" = "true" ]; then
    mv data/actual.jsonl data/expected.jsonl
    echo "Recorded $(wc -l < data/expected.jsonl | tr -d ' ') records to data/expected.jsonl"
    exit 0
fi

if diff -u data/expected.jsonl data/actual.jsonl; then
    echo "Golden test passed"
    rm -f data/actual.jsonl
else
    echo
    echo "Golden test FAILED: emitted log records differ from data/expected.jsonl"
    echo "If the change is intentional, refresh with: make golden-record"
    exit 1
fi
