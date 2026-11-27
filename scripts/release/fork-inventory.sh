#!/usr/bin/env bash
# Step 2. Which contrib-fork components ship, where their patches live, and what to check.
# Usage: fork-inventory.sh <target>
# Columns: component, patch branch, branch head, tag at head, manifest pin, exists upstream@target.
# "upstream=yes" means upstream ships the component too: check whether our patch landed there
# by the target release; if so drop the replace instead of bumping the fork.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "$0")/lib.sh"
[[ $# -eq 1 ]] || die "usage: $0 <target>"

git -C "$CONTRIB_REPO" fetch -q --tags origin
ref=$(upstream_contrib_ref "$1")

{
  echo "COMPONENT BRANCH HEAD TAG-AT-HEAD PINNED UPSTREAM@v$1"
  while read -r path pin; do
    name=$(basename "$path")
    branch=$(patches_branch "$name")
    head=$(git -C "$CONTRIB_REPO" rev-parse --short "origin/$branch" 2>/dev/null || echo "-")
    tag=$(git -C "$CONTRIB_REPO" tag -l "$path/*" --points-at "origin/$branch" 2>/dev/null | sort -V | tail -1)
    up=$(git -C "$CONTRIB_REPO" cat-file -e "$ref:$path/go.mod" 2>/dev/null && echo yes || echo no)
    echo "$path ${branch:-MISSING} $head ${tag:--} $pin $up"
  done < <(fork_replaces)
} | column -t

echo
echo "patch branches not referenced by the manifest (not bumped):"
shipped=$(fork_replaces | while read -r path _; do basename "$path"; done)
git -C "$CONTRIB_REPO" for-each-ref --format='%(refname:lstrip=3)' 'refs/remotes/origin/*-patches' |
  while read -r b; do n=${b//_/}; grep -qx "${n%-patches}" <<<"$shipped" || echo "  $b"; done
