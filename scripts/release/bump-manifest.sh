#!/usr/bin/env bash
# Step 3. Bump manifest.yaml + the Makefile OCB pin to <target>, then check every module exists.
# Usage: bump-manifest.sh <target> <bump-dir from prepare-bump.sh>
#   - dist.version              -> <target>-axoflow.0
#   - core/contrib gomod lines  -> version from versions.txt (contrib fork-only components -> v<target>)
#   - github.com/axoflow/* pins -> v<target>-axoflow.0-rc1 (repin to finals with print-tags.sh flow)
# Leaves vulnerability pins and third-party modules alone; prints what to review by hand.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "$0")/lib.sh"
[[ $# -eq 2 ]] || die "usage: $0 <target> <bump-dir>"
target=$1 map="$2/versions.txt"
[[ -f $map ]] || die "$map missing; run prepare-bump.sh first"

awk -v map="$map" -v t0="v$target" -v dist="$target-axoflow.0" '
  BEGIN { while ((getline l < map) > 0) { split(l, a, " "); v[a[1]] = a[2] } }
  # swap the last token (the version) without reflowing the line
  function setver(nv) { $0 = substr($0, 1, length($0) - length($NF)) nv }
  /^  version: / { setver(dist) }
  /^ *- gomod: / {
    mod = $3
    if (mod in v) setver(v[mod])
    # not required anywhere in contrib (e.g. nopreceiver): follow its line, v0 or core v1
    else if (mod ~ /^go\.opentelemetry\.io\/collector\//) setver($NF ~ /^v0\./ ? t0 : v["go.opentelemetry.io/collector/component"])
    else if (mod ~ /^github\.com\/open-telemetry\/opentelemetry-collector-contrib\//) setver(t0)
    else if (mod ~ /^github\.com\/axoflow\//) setver(t0 "-axoflow.0-rc1")
  }
  /=> +github\.com\/axoflow\// && $NF ~ /-axoflow\./ { setver(t0 "-axoflow.0-rc1") }
  { print }' "$MANIFEST" >"$MANIFEST.tmp" && mv "$MANIFEST.tmp" "$MANIFEST"

sed -E "s/^(OTELCOL_BUILDER_VERSION \?= ).*/\1$target/" "$RELEASES_REPO/Makefile" >"$RELEASES_REPO/Makefile.tmp" &&
  mv "$RELEASES_REPO/Makefile.tmp" "$RELEASES_REPO/Makefile"

# Every upstream module must exist at its new version. Replaced (fork) and axoflow modules are
# skipped: their rc tags don't exist until the fork PRs are tagged.
replaced=$(sed -nE 's#^\s*- (\S+) =>.*#\1#p' "$MANIFEST")
missing=0
while read -r mod ver; do
  grep -qxF "$mod" <<<"$replaced" && continue
  [[ $mod == github.com/axoflow/* ]] && continue
  esc=$(perl -pe 's/([A-Z])/!\l$1/g' <<<"$mod")
  if [[ $mod != go.opentelemetry.io/collector/* && $mod != github.com/open-telemetry/* ]]; then
    echo "REVIEW  third-party $mod $ver (latest: $(curl -fsS "https://proxy.golang.org/$esc/@v/list" | sort -V | tail -1))"
  elif ! curl -fsS -o /dev/null "https://proxy.golang.org/$esc/@v/$ver.info"; then
    echo "MISSING $mod $ver"
    missing=1
  fi
done < <(sed -nE 's/^ *- gomod: (\S+) (\S+)$/\1 \2/p' "$MANIFEST")

echo "REVIEW  replaces: drop any fork whose patch shipped upstream (see fork-inventory.sh); vulnerability pins: check-vuln-pins.sh"
exit "$missing"
