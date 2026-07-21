# Known divergences — permanent, do not re-flag

Intentional differences vs upstream. Flag a file below only when its diff shows upstream
changes *beyond* what the entry describes. Append new entries when the user permanently
rejects something.

## Structural

- **Single distribution** — we ship only `axoflow-otel-collector`; upstream's otelcol,
  otelcol-k8s, otelcol-otlp, otelcol-ebpf-profiler distros, `cmd/opampsupervisor`,
  `cmd/builder`, and their per-distro workflows are permanently not-needed.
- **`manifest.yaml` is ours** — component list is curated per Axoflow needs, versions bumped
  by our own pre/post-update-version scripts. Never diff against upstream manifests.
- **Branding** — `axoflow.ico`, README_linux/README_windows, service/conf file names,
  `linux_config.yaml`/`windows_config.yaml` split.

## Local-only machinery (no upstream counterpart)

- `scripts/ev-sign.sh`, `signer-image/` — EV code signing.
- `scripts/pre-update-version.sh`, `scripts/post-update-version.sh` — our version-bump flow.
- `scripts/prepare-private-modules-gha.{sh,ps1}` — private Go modules in CI.
- `distributions/axoflow-otel-collector/windows-installer.wxs` — kept in-tree (upstream moved
  to a `cmd/msi-generator` template).
- `etw_library_license.txt`, `gofalcon_library_license.txt`.

## Customized shared files

- `scripts/generate-goreleaser.sh` + `cmd/goreleaser/` — reduced to our single distro
  (`distro_axoflow_otel_collector.go`); upstream multi-distro plumbing intentionally dropped.
- `Makefile` — single-distro targets, goreleaser-verify wraps our version scripts.
- `.github/workflows/base-*.yaml` — signing and private-module steps added; upstream
  distro-matrix logic removed.
- `scripts/validate-components.sh` — Axoflow component allowlist.

## Permanently rejected upstream changes

(append `- <upstream path or commit> — <reason>` entries here during runs)

- `cmd/msi-generator/` (fec0c8f) — techdebt: templating our single deeply-customized
  windows-installer.wxs (branding, config persistence, DISABLE_AUTOSTART) is pure cost.
- Snapshot version template `-next` (b2a4951 lineage) — our snapshot pipeline
  (pre-update-version.sh, package-test `*-SNAPSHOT-*` globs) keys on goreleaser's default
  `-SNAPSHOT-` naming.
- Nightly release channel (756b394, 5504f17): withNightlyConfig, nightly workflows/inputs,
  create-issue-on-failure, `package-test.yaml` cron — not-needed.
- `.github/workflows/update-version.yaml` + `bump-versions.sh` — not-needed: otelbot/multi-
  manifest release-prep automation; `-axoflow.N` suffix breaks its semver regex.
- `renovate.json` — not-needed: Renovate app not enabled on the repo.
- prev-tag / generated release-notes plumbing (`--release-header-tmpl`, release-template.md)
  — not-needed: no changelog process.
- OBI/eBPF instrumentation (3ac8983): prepare-obi.sh, fetch-obi action, obi component —
  not-needed for a log-pipeline distro; revisit only on customer demand.
- Expanded arch matrix (386/arm/ppc64le/s390x/riscv64/darwin), GOPPC64 — deliberate
  amd64+arm64-only matrix.
- docker.io publish, otel self-hosted runners (`otel-windows-latest-8-cores`) — org-specific.
- chloggen/changelog machinery, `.github/lychee.toml`, `internal/tools/`, root
  `.goreleaser.yaml`, `docs/release.md`, `distributions/README.md` — upstream community
  process files.
- `tests/msi/{go.mod,go.sum,msi_test.go}` — ours is ahead (vuln fixes, Axoflow install-path
  assertions); never sync from upstream.
- Two-phase `--generate-build-step` build config (9b51357) — our release already splits via
  goreleaser-pro `--split`/`continue --merge` around EV signing; upstream's extra build stage
  exists for OBI/Windows-native needs we don't have. Remnants stay commented out.
- Telemetry prometheus reader defaults (`without_units/type_suffix/scope_info`, 127.0.0.1) —
  would rename self-metrics on :8888 and break dashboards; ours stays `level: basic`.
- `tests/golden/` upstream harness (cmd/golden + self-metrics scrape) — replaced by our own
  log-pipeline golden (filelog → jq canonical diff); upstream's golden tool is metrics-only
  and our manifest has no prometheus receiver. Never sync tests/golden from upstream.

## Deferred (re-raise on future runs)

- Windows-native builds/tests (ad76050, 4b8d649): windows-2022 runners, native Win container
  builds — tangled with our linux wixl+EV-sign MSI flow; user deferred 2026-07-20.
