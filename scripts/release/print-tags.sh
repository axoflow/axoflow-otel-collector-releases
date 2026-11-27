#!/usr/bin/env bash
# Steps 7/9. Print (never run) the push / PR / tag commands for the fork bumps.
# Usage: print-tags.sh rc <target>      after bump-fork-component.sh + your signed commits
#        print-tags.sh final <target>   after the fork PRs are merged
# rc:    push each bump branch, open its PR against the patch branch, tag the PR head -rcN (RC=1).
# final: tag the merged patch branches -axoflow.0 and repin the manifest from rc to final.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "$0")/lib.sh"
[[ $# -eq 2 && ($1 == rc || $1 == final) ]] || die "usage: $0 rc|final <target>"
mode=$1 target=$2
suffix="-axoflow.0"
[[ $mode == rc ]] && suffix="$suffix-rc${RC:-1}"
[[ $mode == final ]] && git -C "$CONTRIB_REPO" fetch -q origin && git -C "$FLUENTFORWARD_REPO" fetch -q origin

# <repo> <github repo> <base branch> <bump branch> <tag>
emit() {
  if [[ $mode == rc ]]; then
    echo "git -C $1 push -u origin $4"
    echo "gh pr create --repo $2 --base $3 --head $4 --title 'chore: upgrade $(basename "${5%/v*}") to v$target'"
    echo "git -C $1 tag -s -m '' $5 $4 && git -C $1 push origin $5"
  else
    echo "git -C $1 tag -s -m '' $5 origin/$3 && git -C $1 push origin $5"
  fi
}

while read -r path _; do
  name=$(basename "$path")
  emit "$CONTRIB_REPO" axoflow/opentelemetry-collector-contrib "$(patches_branch "$name")" \
    "$name-bump-v$target" "$path/v$target$suffix"
done < <(fork_replaces)
emit "$FLUENTFORWARD_REPO" axoflow/fluentforwardexporter main \
  "fluentforwardexporter-bump-v$target" "v$target$suffix"

if [[ $mode == final ]]; then
  echo "# then repin the releases manifest to the final tags and commit:"
  printf "sed -i -E 's/(v%s-axoflow\\\\.0)-rc[0-9]+/\\\\1/' %s\\n" "$target" "$MANIFEST"
fi
