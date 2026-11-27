# Release bump helpers

Deterministic steps for bumping the distribution to a new upstream OpenTelemetry Collector
release. Nothing here pushes, tags, opens PRs or commits in the fork repos: commands that do
are printed for you to run.

Assumes sibling checkouts of `opentelemetry-collector-contrib` and `fluentforwardexporter`
(override with `CONTRIB_REPO=` / `FLUENTFORWARD_REPO=`), `go`, `git`, `curl`, `perl`, `gh` (for the
printed PR commands) and optionally `trivy`. Use the Go version upstream requires (see the generated `go.mod`).

```bash
T=0.166.0                 # upstream release to move to
B=$(mktemp -d)            # scratch dir for this bump: versions, tools, worktrees, logs
R=scripts/release
M=distributions/axoflow-otel-collector/manifest.yaml
```

| # | Command | What it gives you |
|---|---|---|
| 1 | `$R/prepare-bump.sh $T $B` | `$B/versions.txt` (every core/contrib module's version at `$T`), `$B/bin/{ocb,mdatagen}` from upstream's pin |
| 2 | `$R/fork-inventory.sh $T` | shipped forks, their patch branch, head vs tag, whether upstream has the component. `upstream=yes`: check whether our patch landed upstream by the target release; if so drop that `replaces:` line instead of bumping |
| 3 | `$R/bump-manifest.sh $T $B` | manifest + Makefile bumped, forks pinned to `-rc1`, every module checked on proxy.golang.org. Run `make check`, commit: `chore: bump to v$T` |
| 4 | one per fork, see below | each fork bumped on `<name>-bump-v$T`, verified, staged in `$B/wt/<name>` |
| 5 | `sed -i '/^  # Vulnerability patches/,$d' $M && echo '  # Vulnerability patches' >>$M` | old CVE pins cleared (they are the last `replaces:` block). Commit: `chore: clear previous vulnerability pins` |
| 6 | `$R/local-distro-build.sh $B` then `$R/check-vuln-pins.sh $B` | full distro built from the local forks, shipped configs validated, Windows build; which old CVE pins to re-add (KEEP) plus a trivy scan. Commit `fix: vulnerabilities` only if needed |
| 7 | `$R/print-tags.sh rc $T` | push / PR / rc-tag commands for every fork, after you commit each worktree |
| 8 | — | open the releases PR; CI (vuln + build + e2e) runs against the rc tags |
| 9 | `$R/print-tags.sh final $T` | after the fork PRs merge: final tag commands + the manifest repin |
| 10 | `$R/bump-consumers.sh <previous upstream, e.g. 0.156.0> <released tag> $B` | repos in `consumers.txt` bumped on branches (only `<previous>-axoflow.N` is rewritten), plus other files still mentioning the old version, to review. Repos that aren't public keep their own list: `CONSUMERS=<file>` |

Step 4, for every component `fork-inventory.sh` lists (skip ones switched to upstream):

```bash
$R/bump-fork-component.sh ../opentelemetry-collector-contrib etwreceiver-patches receiver/etwreceiver $T $B
$R/bump-fork-component.sh ../fluentforwardexporter main . $T $B
git -C $B/wt/etwreceiver commit -s -m "chore: upgrade to v$T"    # your signing key
```

A failing fork leaves its worktree and `$B/<name>.log`. Typical cause: an upstream Go API change.
Fix it in the worktree and re-run `$R/verify-fork-component.sh $B/wt/<name>/<component-dir>`. If
the fix is a mechanical rename, add a rule to `api-migrations.sed` so the next bump gets it for free.

## Traps these scripts exist for

- **Versions are not one number.** v0.166.0 pairs with core v1.72.0 and contrib v1.5.0
  (`pkg/ottl`, `k8sattributesprocessor`), and modules move between lines (`confighttp`
  v0.156.0 → v1.72.0). Versions come from upstream's go.mods, never from a sed.
- **Patch branches are not rebased.** Their in-repo `../../pkg/*` copies are old code and hide
  modules upstream removed (`pkg/pdatautil`, gone in v0.162). Forks are bumped and verified
  without those replaces, the way the distro resolves them.
- **mdatagen and ocb come from the target's `internal/tools`**, not from the patch branch or `PATH`.
- **Old CVE pins can downgrade.** v0.166.0 already resolved grpc v1.85.0; the v1.83.2 pin would
  have forced it back.
