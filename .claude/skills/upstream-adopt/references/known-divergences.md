# Known divergences — permanent, do not re-flag

Intentional differences vs upstream. Flag a file below only when its diff shows upstream
changes *beyond* what the entry describes. Append new entries when the user permanently
rejects something.

**Last triaged upstream commit:** `d1d9e2a` (2026-11-26). Start the next run's commit
range here and update this line at the end of every run.

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
- `scripts/validate-components.sh` — our `EXCEPTION_COMPONENTS` list replaces upstream's
  standalone allowlist (prometheus/obi entries, ad24bbd); don't port upstream's list.

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
- prev-tag / generated release-notes plumbing (`--release-header-tmpl`, release-template.md)
  — not-needed: no changelog process.
- OBI/eBPF instrumentation (3ac8983): prepare-obi.sh, fetch-obi action, obi component —
  not-needed for a log-pipeline distro; revisit only on customer demand.
- Expanded arch matrix (386/arm/ppc64le/s390x/riscv64/darwin, aix/ppc64 9357d68,
  solaris/amd64 8ff761e), GOPPC64 — deliberate amd64+arm64-only matrix.
- docker.io publish, otel self-hosted runners (`otel-windows-latest-8-cores`) — org-specific.
- chloggen/changelog machinery, `.github/lychee.toml`, `internal/tools/`, root
  `.goreleaser.yaml`, `docs/release.md`, `distributions/README.md` — upstream community
  process files.
- `tests/msi/{go.mod,go.sum,msi_test.go}` — our dependencies are ahead (vuln fixes) and the
  test asserts Axoflow install paths; never sync from upstream (the `go` directive may lag).
- Two-phase `--generate-build-step` build config (9b51357) — our release already splits via
  goreleaser-pro `--split`/`continue --merge` around EV signing; upstream's extra build stage
  exists for OBI/Windows-native needs we don't have. Remnants stay commented out.
- Telemetry prometheus reader defaults (`without_units/type_suffix/scope_info`, 127.0.0.1) —
  would rename self-metrics on :8888 and break dashboards; ours stays `level: basic`.
- `tests/golden/` upstream harness (cmd/golden + self-metrics scrape) — replaced by our own
  log-pipeline golden (filelog → jq canonical diff); upstream's golden tool is metrics-only
  and our manifest has no prometheus receiver. Never sync tests/golden from upstream.

- docker-tests job restructure (5182523, 797d0a1, 4927fab): local image build, docker
  save/upload, separate job, Windows container runs, golden via compose — techdebt; our
  smoke test + log-pipeline golden on the snapshot image cover it.
- `owns_docker_manifests` skip-push guard + `scripts/validate-manifest-ownership.sh`
  (cfc5c6d, 68f249d, 5e7b5b4) — not-needed: one release invocation, no manifest race.
- checksum `split: true` (9f8ee28) — not-needed: checksums come from the single merge job;
  splitting would change the release assets.
- Windows container images are disabled (commented out in distro_axoflow_otel_collector.go):
  nanoserver digest bumps and `WIN_VERSION_SHA` (4927fab, 4aff11c, 8198081) — not-needed.
- `uses: $/.github/workflows/...` (5182523) — never copy; and our release job keeps
  `security-events: write` for the Trivy SARIF upload upstream no longer does.
- `nick-fields/retry` wrappers: GHCR login (a11f4a5), wixl install (35a93e5) — not-needed for
  our 4 release jobs; one more third-party action.
- Per-distribution config JSON schema (733d3d7: cmd/configschemagen,
  scripts/generate-config-schema.sh) — techdebt: ~450 LOC, and it only resolves core/contrib
  namespaces, so our forks and third-party components would be missing.
- `renovate.json` — its OCB/gomod rules clash with our curated manifest and version scripts.
  A minimal github-actions-only config of our own is fine; don't port upstream's.
- Makefile `delete-tags`/`repeat-tags` targets — upstream release process.

## Deferred (re-raise on future runs)

- cosign v3 + sigstore bundle signing (d4e0306, 3adb0a2) — approved 2026-11-27, prepared as
  its own change (branch `chore/cosign-v3`) because it changes the release assets
  (`.sig`/`.pem` → `.sigstore.json`) users verify against. Re-raise if it hasn't landed.

- Windows-native builds/tests (ad76050, 4b8d649): windows-2022 runners, native Win container
  builds — tangled with our linux wixl+EV-sign MSI flow; user deferred 2026-07-20.
