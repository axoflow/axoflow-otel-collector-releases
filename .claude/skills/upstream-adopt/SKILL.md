---
name: upstream-adopt
description: Reviews changes in upstream open-telemetry/opentelemetry-collector-releases against this fork's current state and triages each into adopt / ask / reject, then applies adopted changes on a branch. Use when the user says "sync upstream", "adopt upstream changes", "check what we can pull from upstream", "upstream diff", or "what changed upstream".
---

# Upstream Adopt

Triage upstream `open-telemetry/opentelemetry-collector-releases` changes against this fork.
Baseline is always the **current tree** — diff mapped files against `upstream/main`, no sync
state is stored. We only take what serves this repo (single Axoflow distro, EV signing,
private modules); everything else is rejected with a recorded reason.

## Step 1 — Fetch and diff

Run `scripts/diff-upstream.sh` to fetch upstream and emit per-file diff stats for all mapped
paths plus upstream-only files:

```bash
.claude/skills/upstream-adopt/scripts/diff-upstream.sh
```

Gotcha it handles: this repo's own release tags collide with upstream's — it always fetches
with `--no-tags`. Never `git fetch upstream --tags`.

## Step 2 — Load known divergences

Read [references/known-divergences.md](references/known-divergences.md). Entries there are
permanent, intentional differences — do not re-flag them. Only flag a divergent file when the
diff contains upstream changes *beyond* what the entry describes.

## Step 3 — Gather context per changed file

For each mapped file with a non-empty diff, get the upstream rationale:

```bash
version=$(grep -m1 'version:' distributions/axoflow-otel-collector/manifest.yaml | sed 's/.*: *//; s/-axoflow.*//')
git log --oneline "v${version}..upstream/main" -- <upstream-path>
```

(If the tag range fails, fall back to `git log --oneline -10 upstream/main -- <path>`.)
Read the actual diff hunks, not just stats — triage is per logical change, not per file.
One file can yield multiple findings in different categories.

## Step 4 — Triage

Three categories:

| Category | Criteria |
|---|---|
| **adopt** | Bug/security fixes, CI hardening, tooling bumps (goreleaser, ocb, Go, action pins), package-test improvements — anything that applies cleanly to our single-distro, signed-release setup |
| **ask** | Behavioral changes, structural rewrites of files we customized (goreleaser generation, base workflows, installers), new upstream mechanisms we *could* use (e.g. msi-generator, new scripts/workflows), anything with unclear benefit |
| **reject** | Reason `not-needed`: other distros (otelcol, k8s, otlp, ebpf-profiler), opampsupervisor, builder, .chloggen/changelog, upstream community files. Reason `techdebt`: would add maintenance burden without benefit to us |

When in doubt between adopt and ask → ask. Never silently adopt a change to a file listed in
known-divergences.

## Step 5 — Report

Present one table, one line per finding:

```
category · file (ours) · upstream change summary · reason/benefit
```

Order: adopt, then ask, then reject. For `ask` items state what upstream gains us and what it
costs. Wait for the user's verdicts on `ask` items before applying anything.

## Step 6 — Apply

1. Branch: `chore/upstream-sync-<YYYYMMDD>`.
2. Apply `adopt` items plus approved `ask` items. Port changes by hand into our variants —
   never blind-copy an upstream file over a customized one; re-apply our deltas.
3. Validate: `make generate && make check` must pass. Fix or drop a change that breaks it.
4. If the user permanently rejected something that will keep showing in future diffs, append
   it to [references/known-divergences.md](references/known-divergences.md) in the same run.
5. Commit per logical change (atomic), reference upstream commit SHAs in the message body.

## Path mapping

Direct (same path both sides):

- `Makefile`
- `scripts/{build.sh,generate-goreleaser.sh,validate-components.sh}`
- `scripts/package-tests/*`
- `cmd/goreleaser/main.go`, `cmd/goreleaser/internal/{builder,constants,container,helpers,platforms}.go`
- `.github/workflows/{base-ci-goreleaser,base-package-tests,base-release,ci,msi-tests}.yaml`, `.github/workflows/shellcheck.yml`
- `tests/docker-tests/default-config.yaml`, `tests/msi/*`

Renamed (upstream → ours; upstream's contrib distro is our template):

- `distributions/otelcol-contrib/<f>` → `distributions/axoflow-otel-collector/<f>` for
  `Dockerfile`, `Windows.dockerfile`, `*.conf`, `*.service`, `postinstall.sh`, `preinstall.sh`, `preremove.sh`
- `distributions/otelcol-contrib/config.yaml` → `linux_config.yaml` + `windows_config.yaml`
- `cmd/goreleaser/internal/distro_contrib.go` → `distro_axoflow_otel_collector.go`
- `.github/workflows/ci-goreleaser-contrib.yaml` → `ci-goreleaser-axoflow-otel-collector.yaml`
- `.github/workflows/release-contrib.yaml` → `release-axoflow-otel-collector.yaml`

Upstream-only paths not listed in known-divergences are candidates — triage them (usually
`ask` for new tooling, `reject/not-needed` for other distros).
