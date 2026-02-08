import Foundation
import CoreML
import AVFoundation
import FluidAudio
import os.log

enum ParakeetTranscriptionError: LocalizedError {
    case modelValidationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelValidationFailed(let message):
            return message
        }
    }
}

actor ParakeetTranscriptionService: TranscriptionService {
    static let shared = ParakeetTranscriptionService()

    private let idleTimeout: TimeInterval = 3600
    private var asrManager: AsrManager?
    private var vadManager: VadManager?
    private var activeVersion: AsrModelVersion?
    private var lastUsedAt: Date?
    private var lastTranscriptionAt: Date?
    private var idleEvictionTask: Task<Void, Never>?
    private var isOperationActive = false
    private var operationWaiters: [CheckedContinuation<Void, Never>] = []
    private let logger = Logger(subsystem: "com.prakashjoshipax.voiceink.parakeet", category: "ParakeetTranscriptionService")

    private func version(for model: any TranscriptionModel) -> AsrModelVersion {
        model.name.lowercased().contains("v2") ? .v2 : .v3
    }

    private func ensureModelsLoaded(for version: AsrModelVersion) async throws {
        if let manager = asrManager, activeVersion == version {
            return
        }

        resetResources()

        // Validate models before loading
        let isValid = try await AsrModels.isModelValid(version: version)

        if !isValid {
            logger.error("Model validation failed for \(version == .v2 ? "v2" : "v3"). Models are corrupted.")
            throw ParakeetTranscriptionError.modelValidationFailed("Parakeet models are corrupted. Please delete and re-download the model.")
        }

        let manager = AsrManager(config: .default)
        let models = try await AsrModels.loadFromCache(
            configuration: nil,
            version: version
        )
        try await manager.initialize(models: models)
        self.asrManager = manager
        self.activeVersion = version
    }

    func loadModel(for model: ParakeetModel) async throws {
        try await withOperationLock {
            recordUsage(isTranscription: false)
            defer { resetIdleEvictionTimer() }
            try await ensureModelsLoaded(for: version(for: model))
        }
    }

    func transcribe(audioURL: URL, model: any TranscriptionModel) async throws -> String {
        try await withOperationLock {
            recordUsage(isTranscription: true)
            defer { resetIdleEvictionTimer() }

            let targetVersion = version(for: model)
            try await ensureModelsLoaded(for: targetVersion)

            guard let asrManager = asrManager else {
                throw ASRError.notInitialized
            }

            let audioSamples = try readAudioSamples(from: audioURL)

            let durationSeconds = Double(audioSamples.count) / 16000.0
            let isVADEnabled = UserDefaults.standard.object(forKey: "IsVADEnabled") as? Bool ?? true

            var speechAudio = audioSamples
            if durationSeconds >= 20.0, isVADEnabled {
                let vadConfig = VadConfig(defaultThreshold: 0.7)
                if vadManager == nil {
                    do {
                        vadManager = try await VadManager(config: vadConfig)
                    } catch {
                        logger.notice("VAD init failed; falling back to full audio: \(error.localizedDescription)")
                        vadManager = nil
                    }
                }

                if let vadManager {
                    do {
                        let segments = try await vadManager.segmentSpeechAudio(audioSamples)
                        speechAudio = segments.isEmpty ? audioSamples : segments.flatMap { $0 }
                    } catch {
                        logger.notice("VAD segmentation failed; using full audio: \(error.localizedDescription)")
                        speechAudio = audioSamples
                    }
                }
            }

            let result = try await asrManager.transcribe(speechAudio)

            return result.text
        }
    }

    private func readAudioSamples(from url: URL) throws -> [Float] {
        do {
            let data = try Data(contentsOf: url)
            guard data.count > 44 else {
                throw ASRError.invalidAudioData
            }

            let floats = stride(from: 44, to: data.count, by: 2).map {
                return data[$0..<$0 + 2].withUnsafeBytes {
                    let short = Int16(littleEndian: $0.load(as: Int16.self))
                    return max(-1.0, min(Float(short) / 32767.0, 1.0))
                }
            }

            return floats
        } catch {
            throw ASRError.invalidAudioData
        }
    }

    func cleanup() async {
        await withOperationLock {
            fullyCleanup()
        }
    }

    private func recordUsage(isTranscription: Bool) {
        let now = Date()
        lastUsedAt = now
        if isTranscription {
            lastTranscriptionAt = now
        }
    }

    private func resetIdleEvictionTimer() {
        idleEvictionTask?.cancel()
        idleEvictionTask = nil

        guard let referenceDate = lastUsedAt else { return }

        let elapsed = Date().timeIntervalSince(referenceDate)
        let delay = max(0, idleTimeout - elapsed)
        idleEvictionTask = Task { [weak self] in
            guard let self else { return }
            if delay > 0 {
                do {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } catch {
                    return
                }
            }

            if Task.isCancelled { return }
            await self.performIdleEvictionIfNeeded()
        }
    }

    private func performIdleEvictionIfNeeded() async {
        await withOperationLock {
            guard shouldEvict(for: Date()) else {
                resetIdleEvictionTimer()
                return
            }
            fullyCleanup()
        }
    }

    private func shouldEvict(for date: Date) -> Bool {
        guard let referenceDate = lastTranscriptionAt ?? lastUsedAt else { return false }
        return date.timeIntervalSince(referenceDate) >= idleTimeout
    }

    private func resetResources() {
        asrManager?.cleanup()
        asrManager = nil
        vadManager = nil
        activeVersion = nil
    }

    private func fullyCleanup() {
        resetResources()
        lastUsedAt = nil
        lastTranscriptionAt = nil
        idleEvictionTask?.cancel()
        idleEvictionTask = nil
    }

    private func withOperationLock<T>(_ operation: () async throws -> T) async rethrows -> T {
        await acquireOperationLock()
        defer { releaseOperationLock() }
        return try await operation()
    }

    private func acquireOperationLock() async {
        if !isOperationActive {
            isOperationActive = true
            return
        }

        await withCheckedContinuation { continuation in
            operationWaiters.append(continuation)
        }
    }

    private func releaseOperationLock() {
        if operationWaiters.isEmpty {
            isOperationActive = false
            return
        }

        let next = operationWaiters.removeFirst()
        next.resume()
    }
}
