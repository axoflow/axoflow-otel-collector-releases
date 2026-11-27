#!/usr/bin/env bash
# Step 10. Point downstream repos at the released collector tag (the one actually published,
# including any CVE re-cut suffix).
# Usage: bump-consumers.sh <from, e.g. 0.156.0> <to tag, e.g. 0.166.0-axoflow.0> <bump-dir>
# Only "<from>-axoflow.N" is rewritten: the same files can carry other images' X.Y.Z-axoflow.N
# tags. For a re-cut use from=<same upstream>.
# For each repo in consumers.txt (or the file in CONSUMERS=, for repos that aren't public): worktree <bump-dir>/wt/<repo> on branch
# chore/bump-axoflow-otel-collector-<to> off origin/<base>, rewrites only the listed files, stages.
# Never commits or pushes. Then lists other mentions of <from>-axoflow in those repos, for review.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "$0")/lib.sh"
[[ $# -eq 3 ]] || die "usage: $0 <from> <to-tag> <bump-dir>"
from=${1//./\\.} to=$2 bump=$(cd "$3" && pwd)
list="${CONSUMERS:-$(dirname "$0")/consumers.txt}"

grep -vE '^\s*(#|$)' "$list" | while read -r repo base file; do
  wt=$bump/wt/$repo
  if [[ ! -d $wt ]]; then
    git -C "$WORKSPACE/$repo" fetch -q origin "$base"
    git -C "$WORKSPACE/$repo" worktree add -q --no-track -b "chore/bump-axoflow-otel-collector-$to" "$wt" "origin/$base"
  fi
  old=$(grep -oE "$from-axoflow\.[0-9]+" "$wt/$file" | head -1) || die "$repo/$file: no $1-axoflow.N found"
  sed -E "s/$from-axoflow\.[0-9]+/$to/g" "$wt/$file" >"$wt/$file.tmp" && mv "$wt/$file.tmp" "$wt/$file"
  git -C "$wt" add "$file"
  echo "$repo/$file: $old -> $to"
done

echo
echo "Other files mentioning $1-axoflow, with match counts (historical pins stay; new release-tracking refs go in consumers.txt):"
grep -vE '^\s*(#|$)' "$list" | awk '{print $1}' | sort -u | while read -r repo; do
  git -C "$bump/wt/$repo" grep -cIE "$from-axoflow\.[0-9]+" -- ':!*go.sum' | sed "s#^#  $repo/#" || true
done
