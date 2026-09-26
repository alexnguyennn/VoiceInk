# VoiceInk upgrade port runs

Append a dated entry after each upgrade attempt. Keep commands, revisions, resolved dependencies, outcome, and the reason for including or excluding each local delta. Re-check all conclusions on the next run.

## 2026-09-26 — v2.1 on Xcode 26.3 / Swift 6.2.4

**Inputs and preservation**

- Feature source: `origin/feature/custom-build-update` at `d708a57` (also `backup/custom-build-update-pre-v2.20-port`); two unique commits after upstream v1.79 (`0df2a9a`): `f4c8ccd` trial-date override and `d708a57` local shipping/docs.
- Successful base: upstream `v2.1` at `cced3a0`. Integration result: local `feature/custom-build-update` at `d50955d`, based on v2.1 with the shipping/docs patch reconciled. The old remote branch was not updated.
- The prior v2.13 port was left as uncommitted work in `/Users/alex/bench/dev/VoiceInk` at detached `68b871e`. `backup/custom-build-update-before-2.13` points to upstream v2.20 (`173cbb2`), **not** the original feature tip. Do not confuse these refs when resuming.

**Compatibility evidence**

- On Xcode 26.3 / Apple Swift 6.2.4, v2.13 `make local` failed: the pinned `mlx-swift` 0.31.6 requires Swift tools 6.3. Xcode's automatic resolution to 0.31.4 failed on `MLXHuggingFaceMacros`; an explicit lockfile-only resolution of 0.31.6 failed at the Swift tools check. Generated `Package.resolved` changes were restored.
- Upstream v2.11 also failed package resolution on pinned `mlx-swift` 0.31.6. v2.20 shares the same MLX pin (inferred incompatible from the manifest/lockfile; not a successful build). Among the available newer release tags, v2.1 was the newest actually built with `make local` on this machine.
- v2.1's upstream `Makefile` already builds `.local-build/Build/Products/Debug/VoiceInk.app`. Its `VoiceInk/Models/LicenseViewModel.swift` sets `licenseState = .licensed` under `#if LOCAL_BUILD`. Thus the feature's old 999-day trial/date override was not cherry-picked; local licensed behavior is retained through upstream's build flag.

**Port and verification**

- Cherry-picked the shipping/docs commit `d708a57` onto v2.1, resolving project setting conflicts by keeping `MARKETING_VERSION = 2.0` and setting all six deployment targets to 15.0; normalized the existing trailing whitespace in `CONTRIBUTING.md`.
- `make local` succeeded on the integrated branch. Only after that, `./move.sh` installed and `open /Applications/VoiceInk.app` succeeded. Installed bundle reports version `2.0` and minimum macOS `15.0`.
- `git diff --check` passed. `git diff v2.1..d50955d -- Makefile` was empty; `move.sh` contains no `xcodebuild`. Generated local output is ignored.

**Next sync**

Check available tags, toolchain and package resolution again. Source any feature-only patches from the original remote/backup ref or new branch history, rather than comparing entire upstream trees. Retest `LOCAL_BUILD` semantics and the output path before deciding whether a trial or Makefile patch is needed.
