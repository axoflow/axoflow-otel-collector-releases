#!/usr/bin/env bash
# Step 1. Derive everything version-specific for a bump from upstream contrib v<target>.
# Usage: prepare-bump.sh <target, e.g. 0.166.0> <bump-dir>
# Writes:
#   <bump-dir>/versions.txt  "module version" for every core/contrib module upstream contrib
#                            requires at the tag. Modules sit on different lines (core v1.72.0,
#                            contrib v1.5.0, confighttp moved v0->v1), so never guess versions.
#   <bump-dir>/bin/ocb, <bump-dir>/bin/mdatagen  built from upstream's own internal/tools pin.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "$0")/lib.sh"
[[ $# -eq 2 ]] || die "usage: $0 <target> <bump-dir>"
target=$1
mkdir -p "$2/bin"
bump=$(cd "$2" && pwd)

ref=$(upstream_contrib_ref "$target")

git -C "$CONTRIB_REPO" ls-tree -r --name-only "$ref" | grep '/go\.mod$' |
  while read -r f; do git -C "$CONTRIB_REPO" show "$ref:$f"; done |
  sed -E 's/^require //' |
  awk -v t="v$target" '
    $1 ~ /^(go\.opentelemetry\.io\/collector|github\.com\/open-telemetry\/opentelemetry-collector-contrib\/)/ && $2 ~ /^v[0-9]/ {
      # stale references to removed contrib modules (e.g. pkg/pdatautil v0.101.0) are not targets
      if ($1 ~ /contrib\// && $2 ~ /^v0\./ && $2 != t) next
      print $1, $2
    }' |
  sort -k1,1 -k2,2V | awk '{v[$1] = $2} END {for (m in v) print m, v[m]}' | sort >"$bump/versions.txt"

rm -rf "$bump/tools"
mkdir -p "$bump/tools"
git -C "$CONTRIB_REPO" archive "$ref" internal/tools | tar -x -C "$bump/tools"
(
  cd "$bump/tools/internal/tools"
  go build -o "$bump/bin/ocb" go.opentelemetry.io/collector/cmd/builder
  go build -o "$bump/bin/mdatagen" go.opentelemetry.io/collector/cmd/mdatagen
)

echo "versions: $(wc -l <"$bump/versions.txt") modules -> $bump/versions.txt"
grep -E 'collector/component |contrib/pkg/ottl ' "$bump/versions.txt" | sed 's/^/  /'
echo "ocb:      $("$bump/bin/ocb" version 2>&1)"
echo "mdatagen: $("$bump/bin/mdatagen" --version)"
