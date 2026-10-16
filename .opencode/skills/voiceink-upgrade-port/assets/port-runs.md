# VoiceInk upgrade port runs

Append a dated entry after each upgrade attempt. Keep commands, revisions, resolved dependencies, outcome, and the reason for including or excluding each local delta. Re-check all conclusions on the next run.

## 2026-10-16 — v2.21 on Xcode 26.6 / Swift 6.3.3

**Inputs and preservation**

- Base: upstream tag `v2.21` at `640b0c8c` (2026-09-28). New branch `feature/custom-buld-update-v2.21` created from the tag in `/Users/alex/bench/dev/VoiceInk`; previous branch `feature/custom-build-update-v2.1` (tip `af30ff3`) left intact.
- Feature-only commits cherry-picked from the v2.1 branch: `d50955d` shipping/docs (now `c1ff8ef`) and the four `docs(upgrade)` commits (`050dd07`…`c7e66c2`). Published to `origin/feature/custom-buld-update-v2.21`.

**Compatibility evidence**

- v2.21 still pins `mlx-swift` 0.31.6 (needs Swift tools >= 6.3). The old 6.2.4 blocker is gone: Xcode 26.6 (user-installed at `/Applications/Xcode-26.6.0.app` via Xcodes; `brew install --cask xcode` no longer exists) ships Swift 6.3.3 and package resolution succeeded.
- Homebrew no longer offers an `xcode` cask; Xcode was installed by the user. `xcode-select` still points at CommandLineTools; builds run with `DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer`.
- First `make local` failed only on `CompileMetalFile` for mlx-swift: `cannot execute tool 'metal' due to missing Metal Toolchain`. Fixed with `xcodebuild -downloadComponent MetalToolchain` (Metal Toolchain 17F109); the retry built cleanly. Same sharp edge as the 2026-09-25 v2.20 note — expect it on every fresh Xcode.

**Port and verification**

- v2.21 upstream already carries macOS 15.0 deployment targets, macOS 15.0+ docs, and `#if LOCAL_BUILD` auto-license in `VoiceInk/Features/Licensing/State/LicenseViewModel.swift`; no pbxproj, trial, or Makefile patches were needed (`git diff v2.21..HEAD -- Makefile` empty). Carried deltas: `move.sh`, BUILDING.md `/Applications` install section, `.gitignore` build dirs, upgrade-port docs.
- `move.sh` was retargeted from `Debug` to `.local-build/Build/Products/Release/VoiceInk.app` because v2.21 `make local` builds Release.
- `make local` succeeded; only then `./move.sh` installed. Installed bundle reports version `2.20` (upstream tags without bumping `MARKETING_VERSION`; the tag/commit is the authority) and minimum macOS `15.0`; built and installed executables matched (`cmp`). `open /Applications/VoiceInk.app` succeeded and the process was present. `git diff --check` passed; `move.sh` contains no `xcodebuild`.

**Next sync**

Verify `make local` output path and `LOCAL_BUILD` semantics again; assume a fresh Xcode needs the Metal Toolchain download before the first mlx build.

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

## 2026-09-25 — earlier v2.20 attempt (preserved in original worktree notes)

- The uncommitted `PORT-2.20-PLAN.md` and `AGENT_MEMORY.local.md` in `/Users/alex/bench/dev/VoiceInk` record an earlier attempt. On that checkout with Xcode 26.2, automatic resolution substituted `mlx-swift` 0.31.4 for pinned 0.31.6 and `mlx-swift-lm` failed to compile. `make local` did not succeed; no install followed. The notes also record installing the missing Metal Toolchain via `xcodebuild -downloadComponent MetalToolchain` before reaching that compile failure.
- On v2.20, `make local` builds **Release** and the Debug configuration produces `VoiceInk Dev.app`. The old local-path workaround set `CONFIGURATION_BUILD_DIR` to `.local-build/Build/Products/Debug` while retaining Release; changing to Debug would alter the app identity. This is historical to v2.20: verify the current candidate's Makefile and product name rather than inheriting the workaround.
- The completed checklists in the v2.1 test worktree corroborate the v2.11 failure, v2.1 build success, Sequoia 15.0 deployment settings, and the reconciled `LOCAL_BUILD` licensed behavior documented above. They contain no additional patch to carry forward.

## 2026-09-26 — publish under a new branch and rebuild in the original checkout

- Published integrated port commit `1cea789` to new `origin/feature/custom-build-update-v2.1`, without rewriting `origin/feature/custom-build-update`.
- Before switching the original `/Users/alex/bench/dev/VoiceInk` checkout from detached v2.13 (`68b871e`), saved its tracked and untracked changes as stash commit `110007fe682838acbaf7c789bb778305ed065943`. The stash includes the v2.13 docs/settings, wrapper, prior plan, and local memory; ignored generated build directories were not stashed. Keep this ref until intentionally discarded.
- Switched the original checkout to local `feature/custom-build-update-v2.1` tracking the new remote; both refs were `1cea789` before the rebuild.
- In `/Users/alex/bench/dev/VoiceInk`, `make local` succeeded, then `./move.sh` installed its `.local-build/Build/Products/Debug/VoiceInk.app`. The installed executable matched the built executable (`cmp`); the installed bundle reported version `2.0` and minimum macOS `15.0`. `open /Applications/VoiceInk.app` succeeded and the app process was present. `git diff --check` passed, the v2.1-to-feature Makefile diff was empty, and the wrapper contained no `xcodebuild` invocation.
- Cleanup: the v2.1 bisect worktree's uncommitted changes and notes were saved as stash commit `dda0c69d5d2488c4b8e521b2f2c0c8f293a649b4`. Both auxiliary worktrees were then removed with `git worktree remove`; the original checkout remains the sole worktree. The earlier v2.13 stash `110007fe682838acbaf7c789bb778305ed065943` was retained. Generated ignored build folders in removed worktrees were not archived.
