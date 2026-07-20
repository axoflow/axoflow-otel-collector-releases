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
