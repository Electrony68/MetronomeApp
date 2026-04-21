@preconcurrency import AVFoundation
import Darwin

struct BeatEvent: Sendable {
    let beatIndex: Int
    let sampleTime: Int64
    let sampleRate: Double
}

enum MetronomeError: Error {
    case engineNotRunning
    case noValidRenderTime
}

actor MetronomeEngine {

    nonisolated let beatStream: AsyncStream<BeatEvent>
    private let beatContinuation: AsyncStream<BeatEvent>.Continuation

    private let playerNode = AVAudioPlayerNode()
    private var clickBuffers: [Int: AVAudioPCMBuffer] = [:]
    private var sampleRate: Double = 44_100.0

    private var isRunning = false
    private var currentBPM: BPM = .default
    private var currentTimeSignature: TimeSignature = .fourQuarter
    private var currentAccentPattern = AccentPattern.defaultPattern(for: .fourQuarter)

    // Host-time scheduling (Mach clock — the correct domain for scheduleBuffer(at:)).
    // Sample-time domains (playerNode vs outputNode) have different origins and cause
    // silent buffer drops when stop()/play() cycles occur.
    private var timebase = mach_timebase_info_data_t()
    private var hostTicksPerBeat: UInt64 = 0
    // Incremented on stop or BPM change; callbacks with a stale generation are ignored.
    private var generation: Int = 0

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: BeatEvent.self)
        beatStream       = stream
        beatContinuation = continuation
    }

    // MARK: – Setup

    func setup() async throws {
        mach_timebase_info(&timebase)
        let audioService = AudioEngineService.shared
        sampleRate = await audioService.sampleRate
        guard let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)
        else { return }
        await audioService.attachAndConnect(playerNode, format: stereoFormat)
        generateClickBuffers()
    }

    // MARK: – Playback control

    func start(
        bpm: BPM,
        timeSignature: TimeSignature,
        accentPattern: AccentPattern,
        volume: Float
    ) async throws {
        guard !isRunning else { return }

        currentBPM           = bpm
        currentTimeSignature = timeSignature
        currentAccentPattern = accentPattern
        updateHostTicksPerBeat(bpm: bpm, timeSignature: timeSignature)

        playerNode.volume = volume
        playerNode.play()

        let hostNow = mach_absolute_time()
        isRunning = true
        scheduleClick(hostTime: hostNow + hostTicksPerBeat,     beatIndex: 0)
        scheduleClick(hostTime: hostNow + 2 * hostTicksPerBeat, beatIndex: 1)
    }

    func stop() {
        isRunning = false
        generation += 1
        playerNode.stop()
    }

    func setBPM(_ bpm: BPM) {
        currentBPM = bpm
        updateHostTicksPerBeat(bpm: bpm, timeSignature: currentTimeSignature)
        guard isRunning else { return }
        // Discard pre-scheduled beats (old tempo) and restart the chain.
        // Without this the two interleaved chains drift apart → gallop effect.
        generation += 1
        playerNode.stop()
        playerNode.play()
        let hostNow = mach_absolute_time()
        scheduleClick(hostTime: hostNow + hostTicksPerBeat,     beatIndex: 0)
        scheduleClick(hostTime: hostNow + 2 * hostTicksPerBeat, beatIndex: 1)
    }

    func setAccentPattern(_ pattern: AccentPattern) {
        currentAccentPattern = pattern
    }

    func setVolume(_ volume: Float) {
        playerNode.volume = volume
    }

    // MARK: – Internal scheduling

    private func updateHostTicksPerBeat(bpm: BPM, timeSignature: TimeSignature) {
        let nsPerBeat = UInt64(bpm.beatDuration * timeSignature.beatMultiplier * 1_000_000_000)
        hostTicksPerBeat = nsPerBeat * UInt64(timebase.denom) / UInt64(timebase.numer)
    }

    private func scheduleClick(hostTime: UInt64, beatIndex: Int) {
        let barBeat = beatIndex % currentAccentPattern.beats.count
        let level   = currentAccentPattern.beats[barBeat]
        // .off uses a silent buffer so the callback chain is never broken.
        guard let buffer = clickBuffers[level.rawValue] else { return }

        let capturedHostTime   = hostTime
        let capturedGeneration = generation

        playerNode.scheduleBuffer(
            buffer, at: AVAudioTime(hostTime: hostTime), options: [],
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.onClickCompleted(
                    hostTime: capturedHostTime,
                    beatIndex: beatIndex,
                    generation: capturedGeneration
                )
            }
        }
    }

    private func onClickCompleted(hostTime: UInt64, beatIndex: Int, generation: Int) {
        guard isRunning, generation == self.generation else { return }

        beatContinuation.yield(BeatEvent(
            beatIndex: beatIndex % currentAccentPattern.beats.count,
            sampleTime: Int64(bitPattern: hostTime),
            sampleRate: sampleRate
        ))

        let nextHostTime = hostTime + 2 * hostTicksPerBeat
        scheduleClick(hostTime: nextHostTime, beatIndex: beatIndex + 2)
    }

    // MARK: – Click buffer synthesis

    private func generateClickBuffers() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)
        else { return }
        let bufferFrames = AVAudioFrameCount(UInt32(0.05 * sampleRate))

        // Silent buffer for .off beats — keeps the callback chain alive without sound.
        if let silent = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferFrames) {
            silent.frameLength = bufferFrames
            clickBuffers[AccentLevel.off.rawValue] = silent
        }

        let specs: [(AccentLevel, Double, Float)] = [
            (.strong, 1200.0, 1.0),
            (.medium,  900.0, 0.7),
            (.weak,    700.0, 0.4),
        ]

        for (level, freq, amp) in specs {
            guard
                let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferFrames),
                let ch0 = buffer.floatChannelData?[0],
                let ch1 = buffer.floatChannelData?[1]
            else { continue }

            buffer.frameLength = bufferFrames
            let decay = 40.0
            for i in 0..<Int(bufferFrames) {
                let t = Double(i) / sampleRate
                let sample = amp * Float(exp(-decay * t) * sin(2 * .pi * freq * t))
                ch0[i] = sample
                ch1[i] = sample
            }
            clickBuffers[level.rawValue] = buffer
        }
    }
}
