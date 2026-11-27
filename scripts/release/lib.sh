#!/usr/bin/env bash
# Shared helpers for scripts/release/*. Source it, don't run it.

RELEASES_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# Sibling checkouts by default; override when your layout differs.
WORKSPACE="$(cd "${RELEASES_REPO}/.." && pwd)"
CONTRIB_REPO="${CONTRIB_REPO:-${WORKSPACE}/opentelemetry-collector-contrib}"
FLUENTFORWARD_REPO="${FLUENTFORWARD_REPO:-${WORKSPACE}/fluentforwardexporter}"
MANIFEST="${MANIFEST:-${RELEASES_REPO}/distributions/axoflow-otel-collector/manifest.yaml}"
UPSTREAM_CONTRIB_URL="https://github.com/open-telemetry/opentelemetry-collector-contrib.git"

die() { echo "ERROR: $*" >&2; exit 1; }

# Fetch upstream contrib tag v<ver> into the contrib checkout as refs/tags/upstream-v<ver>
# (prefixed so it can't collide with the fork's own tags). Prints the ref.
upstream_contrib_ref() {
  local ref="refs/tags/upstream-v$1"
  git -C "$CONTRIB_REPO" rev-parse -q --verify "$ref" >/dev/null ||
    git -C "$CONTRIB_REPO" fetch -q --no-tags "$UPSTREAM_CONTRIB_URL" "refs/tags/v$1:$ref"
  echo "$ref"
}

# "<component path> <pinned version>" for every manifest replace pointing at the contrib fork,
# e.g. "receiver/etwreceiver v0.166.0-axoflow.0-rc1".
fork_replaces() {
  sed -nE 's#^\s*- \S+ => +github\.com/axoflow/opentelemetry-collector-contrib/(\S+) (\S+)$#\1 \2#p' "$MANIFEST"
}

# The fork's patch branch for a component name. Branch names are not uniform
# (crowdstrikefdrreceiver lives on crowdstrike_fdrreceiver-patches), so match ignoring "_".
patches_branch() {
  git -C "$CONTRIB_REPO" for-each-ref --format='%(refname:lstrip=3)' 'refs/remotes/origin/*-patches' |
    while read -r b; do if [[ "${b//_/}" == "$1-patches" ]]; then echo "$b"; fi; done
}
