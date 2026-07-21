#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_URL="https://github.com/open-telemetry/opentelemetry-collector-releases.git"

if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "$UPSTREAM_URL"
fi
# --no-tags: our release tags collide with upstream's
git fetch upstream main --no-tags --quiet

echo "## upstream/main: $(git rev-parse --short upstream/main) ($(git log -1 --format=%cs upstream/main))"
echo

DIRECT_PATHS=(
  Makefile
  scripts/build.sh
  scripts/generate-goreleaser.sh
  scripts/validate-components.sh
  scripts/package-tests
  cmd/goreleaser/main.go
  cmd/goreleaser/internal/builder.go
  cmd/goreleaser/internal/constants.go
  cmd/goreleaser/internal/container.go
  cmd/goreleaser/internal/helpers.go
  cmd/goreleaser/internal/platforms.go
  .github/workflows/base-ci-goreleaser.yaml
  .github/workflows/base-package-tests.yaml
  .github/workflows/base-release.yaml
  .github/workflows/ci.yaml
  .github/workflows/msi-tests.yaml
  .github/workflows/shellcheck.yml
  tests/docker-tests/default-config.yaml
  tests/msi
)

echo "## Direct-mapped paths (ours vs upstream/main)"
for p in "${DIRECT_PATHS[@]}"; do
  git diff --stat HEAD upstream/main -- "$p" | sed '$d'
done
echo

RENAMED_PAIRS=(
  "distributions/axoflow-otel-collector/Dockerfile:distributions/otelcol-contrib/Dockerfile"
  "distributions/axoflow-otel-collector/Windows.dockerfile:distributions/otelcol-contrib/Windows.dockerfile"
  "distributions/axoflow-otel-collector/axoflow-otel-collector.conf:distributions/otelcol-contrib/otelcol-contrib.conf"
  "distributions/axoflow-otel-collector/axoflow-otel-collector.service:distributions/otelcol-contrib/otelcol-contrib.service"
  "distributions/axoflow-otel-collector/postinstall.sh:distributions/otelcol-contrib/postinstall.sh"
  "distributions/axoflow-otel-collector/preinstall.sh:distributions/otelcol-contrib/preinstall.sh"
  "distributions/axoflow-otel-collector/preremove.sh:distributions/otelcol-contrib/preremove.sh"
  "distributions/axoflow-otel-collector/linux_config.yaml:distributions/otelcol-contrib/config.yaml"
  "cmd/goreleaser/internal/distro_axoflow_otel_collector.go:cmd/goreleaser/internal/distro_contrib.go"
  ".github/workflows/ci-goreleaser-axoflow-otel-collector.yaml:.github/workflows/ci-goreleaser-contrib.yaml"
  ".github/workflows/release-axoflow-otel-collector.yaml:.github/workflows/release-contrib.yaml"
)

echo "## Renamed-mapped files (ours vs upstream counterpart, diff line counts)"
for pair in "${RENAMED_PAIRS[@]}"; do
  ours="${pair%%:*}"
  theirs="${pair#*:}"
  if ! git cat-file -e "upstream/main:${theirs}" 2>/dev/null; then
    echo "GONE upstream: ${theirs} (ours: ${ours})"
    continue
  fi
  lines=$(git diff "HEAD:${ours}" "upstream/main:${theirs}" | wc -l | tr -d ' ')
  echo "${lines} ${ours} <- ${theirs}"
done
echo

echo "## Upstream-only files (no local counterpart, potential candidates)"
comm -13 \
  <(git ls-tree -r --name-only HEAD | sort) \
  <(git ls-tree -r --name-only upstream/main | sort) |
  grep -Ev '^(distributions/(otelcol|otelcol-k8s|otelcol-otlp|otelcol-ebpf-profiler|otelcol-contrib)/|cmd/opampsupervisor/|cmd/builder/|cmd/goreleaser/internal/distro_|\.chloggen/|CHANGELOG|CONTRIBUTING|SECURITY|AGENTS\.md|\.github/(CODEOWNERS|pull_request_template|release-template)|\.github/workflows/(ci-goreleaser-|release-|ci-opampsupervisor|ci-builder|nightly-release|fossa|ossf-scorecard|stale))' || true
