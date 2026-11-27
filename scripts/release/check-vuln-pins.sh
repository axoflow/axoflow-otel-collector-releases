#!/usr/bin/env bash
# Step 6. Decide which vulnerability pins a bump still needs, then scan what's left.
# Usage: check-vuln-pins.sh <bump-dir> [git-ref with the old pins, default: main]
# For each "# Vulnerability patches" replace in the manifest at <ref>, compares the pinned version
# with what the freshly built distro (<bump-dir>/distro/_build, built with the pins cleared)
# resolves. KEEP = upstream still resolves an older version. A pin kept by mistake can silently
# *downgrade* a dependency. Then runs the same trivy scan CI runs, on the resolved go.mod.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "$0")/lib.sh"
[[ $# -ge 1 ]] || die "usage: $0 <bump-dir> [ref]"
build=$(cd "$1/distro/_build" && pwd)
ref=${2:-main}

git -C "$RELEASES_REPO" show "$ref:distributions/axoflow-otel-collector/manifest.yaml" |
  sed -n '/# Vulnerability patches/,$p' | sed -nE 's/^\s*- (\S+) => \S+ (v\S+)$/\1 \2/p' |
  while read -r mod want; do
    have=$(cd "$build" && go list -m -f '{{.Version}}' "$mod" 2>/dev/null) || have=""
    if [[ -z $have ]]; then
      echo "DROP $mod (no longer a dependency)"
    elif [[ $(printf '%s\n%s\n' "$want" "$have" | sort -V | head -1) == "$want" ]]; then
      echo "DROP $mod resolves $have >= pinned $want"
    else
      echo "KEEP $mod resolves $have < pinned $want"
    fi
  done

if command -v trivy >/dev/null; then
  scan=$(mktemp -d)
  cp "$build/go.mod" "$build/go.sum" "$scan/"
  trap 'rm -rf "$scan"' EXIT
  trivy fs --quiet --scanners vuln --format table --exit-code 1 "$scan" && echo "trivy: no vulnerabilities"
else
  echo "trivy not installed; CI's vulnerability-check workflow will scan instead"
fi
