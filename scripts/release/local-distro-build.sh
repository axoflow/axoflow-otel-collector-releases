#!/usr/bin/env bash
# Step 6. Build the whole distro against the local fork worktrees, before any rc tag exists.
# Usage: local-distro-build.sh <bump-dir>
# Writes <bump-dir>/distro/manifest.yaml with every fork replace pointed at <bump-dir>/wt/<name>,
# builds it with <bump-dir>/bin/ocb, validates the shipped configs with the binary and
# cross-compiles for Windows. <bump-dir>/distro/_build/go.mod is the input for check-vuln-pins.sh.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "$0")/lib.sh"
[[ $# -eq 1 ]] || die "usage: $0 <bump-dir>"
bump=$(cd "$1" && pwd)
out=$bump/distro
mkdir -p "$out"

awk -v wt="$bump/wt" -v out="$out/_build" '
  /^  output_path: / { $0 = "  output_path: " out }
  match($0, /=> +github\.com\/axoflow\/opentelemetry-collector-contrib\/[^ ]+/) {
    path = substr($0, RSTART, RLENGTH); sub(/^=> +github\.com\/axoflow\/opentelemetry-collector-contrib\//, "", path)
    n = split(path, p, "/")
    $0 = substr($0, 1, RSTART - 1) "=> " wt "/" p[n] "/" path
  }
  { print }' "$MANIFEST" >"$out/manifest.yaml"
if [[ -d $bump/wt/fluentforwardexporter ]]; then
  echo "  - github.com/axoflow/fluentforwardexporter => $bump/wt/fluentforwardexporter" >>"$out/manifest.yaml"
fi
grep -nE '=> .*/wt/' "$out/manifest.yaml" | sed 's/^/local: /'

"$bump/bin/ocb" --config "$out/manifest.yaml" >"$out/build.log" 2>&1 || die "build failed, see $out/build.log"
bin=$out/_build/axoflow-otel-collector
"$bin" --version

for c in "$RELEASES_REPO"/distributions/axoflow-otel-collector/*config*.yaml "$RELEASES_REPO"/tests/docker-tests/default-config.yaml; do
  "$bin" validate --config "$c" >/dev/null 2>"$out/validate.log" || die "invalid $c: $(tail -3 "$out/validate.log")"
  echo "valid   $c"
done

(cd "$out/_build" && CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -trimpath -o "$out/axoflow-otel-collector.exe" .)
echo "windows $out/axoflow-otel-collector.exe"
