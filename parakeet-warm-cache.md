# Parakeet Warm Cache + Idle Unload Plan

## Stage 1 — Confirm scope and success measures
- **Goal:** Lock in the exact behaviors for Parakeet warm caching and idle unload so implementation is unambiguous.
- **Scope:**
  - **In:** Keep Parakeet models resident between dictations; unload after 1 hour of **no transcription calls**; keep prewarm behavior as-is.
  - **Out:** Any UI additions for configuring idle timeout, or user-facing settings changes.
- **Requirements:**
  1. Idle timer resets on any Parakeet `loadModel` or `transcribe` call; “unused” means no transcription calls for 1 hour.
  2. Switching to a different model does **not** immediately unload Parakeet; idle timer governs eviction.
  3. Parakeet operations are serialized (single in-flight load/transcribe).
  4. `make build` will be executed after code changes.
- **Constraints:** Swift/SwiftUI codebase; must continue using FluidAudio; avoid new dependencies; keep prewarm logic unchanged.
- **Acceptance criteria:**
  - All above requirements are explicitly represented in the implementation steps below.
- **Completion promise:** <promise>COMPLETE</promise>

## Stage 2 — Parakeet service lifecycle + idle eviction
- **Goal:** Keep Parakeet models warm across dictations with a safe, serialized, shared service and idle eviction.
- **Scope:**
  - **In:** Convert `ParakeetTranscriptionService` to a shared, concurrency-safe singleton; add idle unload after 1h of no transcription calls.
  - **Out:** Any changes to transcription accuracy/parameters.
- **Requirements:**
  1. `ParakeetTranscriptionService` becomes an `actor` with a `shared` instance.
  2. `loadModel` and `transcribe` are serialized (single in-flight access).
  3. `lastUsedAt` is updated on `loadModel` and `transcribe`, and idle eviction runs after 1 hour of no transcription calls.
  4. Idle eviction cleans up `asrManager`, `vadManager`, and `activeVersion` and cancels its timer.
  5. Model re-load uses the existing validation + cache load + initialize path; no behavior regression in error handling.
- **Constraints:** Actor isolation; avoid blocking the main thread; no new dependencies.
- **Acceptance criteria:**
  - Successive dictations reuse the existing Parakeet `asrManager` without revalidation/reinit.
  - After 1h of no transcription calls, Parakeet is cleaned up and will reinitialize on next use.
  - Concurrent calls do not interleave or race.
- **Completion promise:** <promise>NOT_STARTED</promise>

## Stage 3 — Integrate with app lifecycle + cleanup call sites
- **Goal:** Ensure all app paths use the shared Parakeet service and avoid unnecessary teardown, while preserving explicit cleanup on delete.
- **Scope:**
  - **In:** Update service registry and cleanup paths; wire delete action to async cleanup; optional prewarm on Parakeet default.
  - **Out:** Any changes to user-facing behavior outside transcription speed.
- **Requirements:**
  1. `TranscriptionServiceRegistry` uses the shared Parakeet service instance.
  2. Remove Parakeet cleanup from `cleanupModelResources()` (leave Whisper cleanup intact).
  3. Remove Parakeet cleanup from `AudioFileTranscriptionManager` defers (do not tear down shared service).
  4. `deleteParakeetModel` awaits Parakeet cleanup before deleting cache.
  5. Model selection for Parakeet can optionally trigger a background warm load (no UI change).
  6. Switching models does **not** force Parakeet unload (idle timer governs eviction).
- **Constraints:** Avoid UI blocking; keep prewarm behavior as-is; only touch necessary files.
- **Acceptance criteria:**
  - No Parakeet cleanup occurs on `dismissMiniRecorder()` or routine transcription flows.
  - Deleting Parakeet explicitly cleans up resources before removing on-disk cache.
  - All Parakeet usage routes through the shared instance.
- **Completion promise:** <promise>NOT_STARTED</promise>

## Stage 4 — Build verification
- **Goal:** Confirm the project builds after changes.
- **Scope:**
  - **In:** Run `make build`.
  - **Out:** Additional tests or benchmarks (unless failures require follow-up).
- **Requirements:**
  1. `make build` is executed after code changes.
  2. Any build errors are resolved or documented with next steps.
- **Constraints:** Do not bypass hooks or disable tests.
- **Acceptance criteria:**
  - `make build` completes successfully.
- **Completion promise:** <promise>NOT_STARTED</promise>
