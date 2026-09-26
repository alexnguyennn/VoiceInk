---
name: voiceink-upgrade-port
description: >-
  Ports VoiceInk local build and install changes onto a compatible upstream tag or main branch. Use for upgrade port, sync custom-build-update, rebase VoiceInk onto upstream, make local failures, Swift toolchain compatibility, local trial bypass, or moving the built app to /Applications; records each port's decisions and evidence.
---

# VoiceInk upgrade port

**Scope**

Use upstream source and build automation as the base. Read the latest entry in [assets/port-runs.md](assets/port-runs.md) for prior reasoning, then verify its assumptions against the candidate; historical results are evidence, not permanent version rules.

**Choose a base**

- Inspect status, remote/tag refs, the actual feature-only commits, and toolchain versions before changing branches. Preserve dirty work and the previous branch tip with a named ref or separate worktree.
- Test candidate tags in isolated worktrees with `make local`. A pinned package or moving branch dependency may invalidate an old success; record the exact commit and resolved version when it does. Pick the newest candidate that actually builds on the available toolchain.

**Port only intentional deltas**

- Reconcile the feature-only commits against that base. Keep `move.sh` pointed at `.local-build/Build/Products/Debug/VoiceInk.app`, the docs and deployment targets at macOS Sequoia 15.0+, and generated build folders ignored.
- Inspect the candidate's `LOCAL_BUILD` licensing behavior before carrying forward trial changes. If it already grants local use, preserve that mechanism rather than transplanting an obsolete trial-date override.
- Leave the upstream `Makefile` unchanged when `make local` produces the expected app path; change it only if that contract breaks.

**Verify and record**

- Run `make local` successfully before `./move.sh`; then verify `/Applications/VoiceInk.app` exists, its minimum OS and version, and `open /Applications/VoiceInk.app` succeeds.
- Run `git diff --check` and inspect `git diff -- Makefile` against the selected upstream base, including any committed port changes. Verify the installer never invokes `xcodebuild`.
- Append a dated entry to [assets/port-runs.md](assets/port-runs.md) with base and feature refs, environment, candidates/results, decisions, verification, blockers, and rollback refs. Distinguish a successful build from a package-only check. Do not install after a failed build.

**Test this skill**

For a request to sync onto a new tag, confirm the first action reads the prior run, checks refs and toolchain, and selects an isolated test worktree before modifying the primary branch. For a failed build, confirm installation is gated and the log captures the exact failure. Tighten this workflow if either check fails.
