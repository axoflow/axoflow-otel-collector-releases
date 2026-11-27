#!/usr/bin/env bash
# Step 4. Bump one fork component to <target> on a new branch, verify it, stage the result.
# Usage: bump-fork-component.sh <repo> <base-branch> <component-dir> <target> <bump-dir>
#   contrib:       bump-fork-component.sh "$CONTRIB_REPO" etwreceiver-patches receiver/etwreceiver 0.166.0 /tmp/bump
#   fluentforward: bump-fork-component.sh "$FLUENTFORWARD_REPO" main . 0.166.0 /tmp/bump
# Creates worktree <bump-dir>/wt/<name> on branch <name>-bump-v<target> (override: BRANCH=...)
# off origin/<base-branch>. Never commits or pushes: fork repos sign commits with personal keys.
# Run components one after another; parallel `git worktree add` calls race on .git/config.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
[[ $# -eq 5 ]] || { echo "usage: $0 <repo> <base-branch> <component-dir> <target> <bump-dir>" >&2; exit 1; }
repo=$1 base=$2 cdir=$3 target=$4 bump=$(cd "$5" && pwd)
[[ -f $bump/versions.txt && -x $bump/bin/mdatagen ]] || { echo "run prepare-bump.sh first" >&2; exit 1; }
if [[ $cdir == . ]]; then name=$(basename "$(cd "$repo" && pwd)"); else name=$(basename "$cdir"); fi
branch=${BRANCH:-$name-bump-v$target}
wt=$bump/wt/$name
log=$bump/$name.log

git -C "$repo" fetch -q origin "$base"
git -C "$repo" worktree add -q --no-track -b "$branch" "$wt" "origin/$base"
cd "$wt/$cdir"

steps() {
  # 1. Versions from upstream's own go.mods. Contrib modules upstream doesn't have at <target>
  #    (removed upstream, or fork-only) lose their require line; tidy re-adds what is really used.
  awk -v map="$bump/versions.txt" '
    BEGIN { while ((getline l < map) > 0) { split(l, a, " "); v[a[1]] = a[2] } }
    {
      m = ($1 == "require") ? $2 : $1; ver = ($1 == "require") ? $3 : $2
      if (ver ~ /^v[0-9]/ && m ~ /^(go\.opentelemetry\.io\/collector|github\.com\/open-telemetry\/opentelemetry-collector-contrib\/)/) {
        if (m in v) { i = index($0, m " " ver); $0 = substr($0, 1, i - 1) m " " v[m] substr($0, i + length(m " " ver)) }
        else if (m ~ /contrib\//) next
      }
      print
    }' go.mod >go.mod.tmp && mv go.mod.tmp go.mod

  # 2. Patch branches are never rebased, so in-repo `=> ../` copies are stale (v<previous> code)
  #    and would hide removed upstream modules. Resolve real upstream modules, like the distro does.
  grep -v '=> \.\./' go.mod >go.mod.tmp && mv go.mod.tmp go.mod

  # 3. Known Go API renames.
  find . -name '*.go' -not -path './internal/metadata/*' | while read -r f; do
    sed -E -f "$here/api-migrations.sed" "$f" >"$f.tmp"
    if cmp -s "$f" "$f.tmp"; then rm "$f.tmp"; else mv "$f.tmp" "$f" && gofmt -w "$f"; fi
  done

  # 4. Regenerate with the target's mdatagen. Repos that never tracked mdatagen's generated
  #    tests (fluentforwardexporter) keep not tracking them.
  rm -f go.sum
  go mod tidy
  "$bump/bin/mdatagen" metadata.yaml
  git ls-files --others --exclude-standard -- . | { grep -E 'generated_[a-z]+_test\.go$' || true; } | xargs rm -f
  go mod tidy

  "$here/verify-fork-component.sh" .
}
# Not `steps || ...`: that would switch off `set -e` inside steps.
trap 'echo "FAIL $name (log: $log, worktree: $wt)" >&2' EXIT
steps >"$log" 2>&1
trap - EXIT

git add -A .
echo "OK   $name staged on $branch in $wt"
echo "     commit: git -C $wt commit -s -m 'chore: upgrade to v$target'"
