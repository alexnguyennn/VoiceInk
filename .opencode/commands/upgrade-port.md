# Upgrade Port Command

Use this when porting local VoiceInk build/install glue onto a fresh upstream base.

## Goal

Stay as close to `upstream-official/main` as possible. Keep upstream build files intact, then layer only the local wrapper flow needed to produce and install a local `.app`.

## Workflow

1. Start from `upstream-official/main` or a branch rebased/reset to it.
2. Preserve intentional local deltas only:
   - `move.sh` installs `.local-build/Build/Products/Debug/VoiceInk.app` to `/Applications/VoiceInk.app`.
   - macOS support is Sequoia 15.0 or newer in docs and deployment settings.
   - local trial bypass remains intentional.
   - generated local build folders stay ignored.
3. Do not modify `Makefile` unless upstream `make local` stops producing `.local-build/Build/Products/Debug/VoiceInk.app`.
4. Build with upstream automation:

```bash
make local
```

5. Install the produced app with the local wrapper:

```bash
./move.sh
```

6. Verify the installed app exists:

```bash
open /Applications/VoiceInk.app
```

## Checks

- `make local` must succeed before running `move.sh`.
- `move.sh` must not run its own `xcodebuild`; it only moves the Makefile output.
- `git diff --check` should pass.
- `git diff -- Makefile` should be empty unless upstream changed the local build output path.
