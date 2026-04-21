import Foundation
import Observation

@Observable
@MainActor
final class MetronomeViewModel {

    // MARK: – Publikt tillstånd (UI binder mot dessa)
    var bpm: BPM                          = .default
    var timeSignature: TimeSignature      = .fourQuarter
    var accentPattern: AccentPattern      = AccentPattern.defaultPattern(for: .fourQuarter)
    var metronomeVolume: Float            = 0.8
    var mixWithOthers: Bool               = false
    var autoAccelerateSettings: AutoAccelerateSettings? = nil

    var isPlaying: Bool      = false
    var currentBeatIndex: Int = 0
    var errorMessage: String? = nil

    // MARK: – Privat
    private let engine = MetronomeEngine()
    private var beatTask: Task<Void, Never>? = nil

    private var tapTimestamps: [Date] = []
    private let maxTaps = 8

    private var barCount: Int = 0
    private var lastDroneVolume: Float = 0.7   // bevarat från PersistenceService-laddning

    // MARK: – Setup

    func setup() async {
        do {
            try await AudioEngineService.shared.configure(mixWithOthers: mixWithOthers)
            try await engine.setup()
            try await AudioEngineService.shared.start()
            await loadSettings()
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

    private func loadSettings() async {
        guard let s = try? await PersistenceService.shared.loadMetronomeSettings() else { return }
        bpm                    = s.bpm
        timeSignature          = s.timeSignature
        accentPattern          = s.accentPattern
        metronomeVolume        = s.metronomeVolume
        mixWithOthers          = s.mixWithOthers
        autoAccelerateSettings = s.autoAccelerate
        lastDroneVolume        = s.droneVolume
    }

    func saveSettings() async {
        let settings = MetronomeSettings(
            bpm: bpm,
            timeSignature: timeSignature,
            accentPattern: accentPattern,
            metronomeVolume: metronomeVolume,
            droneVolume: lastDroneVolume,
            mixWithOthers: mixWithOthers,
            autoAccelerate: autoAccelerateSettings
        )
        try? await PersistenceService.shared.saveMetronomeSettings(settings)
    }

    // MARK: – Uppspelningskontroll

    func togglePlayback() async {
        if isPlaying {
            await engine.stop()
            isPlaying = false
            cancelBeatTask()
        } else {
            do {
                try await AudioEngineService.shared.ensureRunning()
                try await engine.start(
                    bpm: bpm,
                    timeSignature: timeSignature,
                    accentPattern: accentPattern,
                    volume: metronomeVolume
                )
                isPlaying = true
                barCount  = 0
                startBeatTask()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func stop() async {
        guard isPlaying else { return }
        await engine.stop()
        isPlaying = false
        cancelBeatTask()
    }

    // MARK: – Parameterändringar

    func setBPM(_ newBPM: BPM) {
        bpm = newBPM
        Task { await self.engine.setBPM(newBPM) }
    }

    func setTimeSignature(_ ts: TimeSignature) async {
        timeSignature = ts
        accentPattern = AccentPattern.defaultPattern(for: ts)
        guard isPlaying else { return }
        isPlaying = false
        await engine.stop()
        cancelBeatTask()
        do {
            try await engine.start(
                bpm: bpm,
                timeSignature: ts,
                accentPattern: accentPattern,
                volume: metronomeVolume
            )
            isPlaying = true
            startBeatTask()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setAccentPattern(_ pattern: AccentPattern) async {
        accentPattern = pattern
        await engine.setAccentPattern(pattern)
    }

    func setVolume(_ volume: Float) async {
        metronomeVolume = volume
        await engine.setVolume(volume)
    }

    // MARK: – Tap Tempo

    func tapTempo() {
        tapTimestamps.append(Date())
        if tapTimestamps.count > maxTaps { tapTimestamps.removeFirst() }
        guard tapTimestamps.count >= 2 else { return }
        let intervals = zip(tapTimestamps, tapTimestamps.dropFirst()).map { $1.timeIntervalSince($0) }
        let avg = intervals.reduce(0.0, +) / Double(intervals.count)
        setBPM(BPM(rawValue: 60.0 / avg))
    }

    func resetTapTempo() {
        tapTimestamps.removeAll()
    }

    // MARK: – Beat-stream och auto-accelerate

    private func startBeatTask() {
        beatTask = Task { [weak self] in
            guard let self else { return }
            for await event in self.engine.beatStream {
                self.currentBeatIndex = event.beatIndex
                self.handleAutoAccelerate(beatIndex: event.beatIndex)
            }
        }
    }

    private func cancelBeatTask() {
        beatTask?.cancel()
        beatTask = nil
    }

    private func handleAutoAccelerate(beatIndex: Int) {
        guard let auto = autoAccelerateSettings, beatIndex == 0 else { return }
        barCount += 1
        guard barCount % auto.afterBars == 0 else { return }
        guard bpm.rawValue < auto.targetBPM.rawValue else { return }
        let newBPM = BPM(rawValue: min(bpm.rawValue + auto.bpmIncrement, auto.targetBPM.rawValue))
        bpm = newBPM
        Task { await self.engine.setBPM(newBPM) }
    }
}
