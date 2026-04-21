import Foundation
import Observation

@Observable
@MainActor
final class DroneViewModel {

    // MARK: – Publikt tillstånd
    var configuration: DroneConfiguration = DroneConfiguration()
    var isPlaying: Bool      = false
    var errorMessage: String? = nil

    // MARK: – Privat
    private let engine = DroneEngine()

    // MARK: – Setup

    func setup() async {
        do {
            try await engine.setup()
            await loadConfiguration()
        } catch {
            errorMessage = error.localizedDescription
        }
        await startUnexpectedStopObserver()
    }

    private var stopObserverTask: Task<Void, Never>?

    private func startUnexpectedStopObserver() async {
        stopObserverTask?.cancel()
        let stream = await AudioEngineService.shared.makeStopStream()
        stopObserverTask = Task { [weak self] in
            for await _ in stream {
                guard let self else { return }
                await self.stop()
            }
        }
    }

    private func loadConfiguration() async {
        if let config = try? await PersistenceService.shared.loadDroneConfiguration() {
            configuration = config
        }
    }

    func saveConfiguration() async {
        try? await PersistenceService.shared.saveDroneConfiguration(configuration)
    }

    // MARK: – Uppspelningskontroll

    func togglePlayback() async {
        if isPlaying {
            await engine.stop()
            isPlaying = false
        } else {
            do {
                try await AudioEngineService.shared.ensureRunning()
                await engine.start(config: configuration)
                isPlaying = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func stop() async {
        guard isPlaying else { return }
        await engine.stop()
        isPlaying = false
    }

    // MARK: – Konfigurationsändringar

    func setKey(_ key: MusicalKey) async {
        configuration.key = key
        await engine.updateConfiguration(configuration)
    }

    func setScaleMode(_ mode: ScaleMode) async {
        configuration.scaleMode = mode
        await engine.updateConfiguration(configuration)
    }

    func setOctave(_ octave: Octave) async {
        configuration.octave = octave
        await engine.updateConfiguration(configuration)
    }

    func setWaveform(_ waveform: Waveform) async {
        configuration.waveform = waveform
        await engine.updateConfiguration(configuration)
    }

    func setInterval(_ interval: DroneInterval) async {
        configuration.additionalInterval = interval
        await engine.updateConfiguration(configuration)
    }

    func setVolume(_ volume: Float) async {
        configuration.volume = volume
        await engine.updateConfiguration(configuration)
    }

    func setReferenceA4(_ hz: Double) async {
        configuration.referenceA4 = hz.clamped(to: DroneConfiguration.referenceRange)
        await engine.updateConfiguration(configuration)
    }

    func applyConfiguration(_ config: DroneConfiguration) async {
        configuration = config
        await engine.updateConfiguration(config)
    }
}
