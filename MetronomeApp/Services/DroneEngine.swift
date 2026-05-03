@preconcurrency import AVFoundation
import Darwin

// State shared between the actor and the lock-free audio-thread render callback.
// All nonisolated(unsafe) properties are written from the actor and read on the
// audio thread. Simple scalar types on ARM64 are written atomically.
private final class SynthState: @unchecked Sendable {

    // --- Parameters (actor ↔ audio thread) ---
    nonisolated(unsafe) var isRunning: Bool   = false
    nonisolated(unsafe) var wantRelease: Bool = false

    // Up to 5 simultaneous frequencies (root/third/fourth/fifth/seventh)
    nonisolated(unsafe) var frequencies: [Double] = [440, 440, 440, 440, 440]
    nonisolated(unsafe) var frequencyCount: Int    = 1

    nonisolated(unsafe) var volume: Float  = 0.7
    nonisolated(unsafe) var waveformRaw: Int = 0   // 0 = organ, 1 = strings

    nonisolated(unsafe) var sampleRate: Double = 44_100.0
    nonisolated(unsafe) var attackIncrement: Double  = 1.0 / 2_205.0
    nonisolated(unsafe) var releaseIncrement: Double = 1.0 / 2_205.0

    // --- Audio-thread-only synthesis state ---
    var phases: [Double]       = [0, 0, 0, 0, 0]
    var filterStates: [Double] = [0, 0, 0, 0, 0]
    var lfoVibratoPhase: Double = 0.0  // Strings: 5 Hz pitch vibrato
    var lfoTremoloPhase: Double = 0.0  // Organ: 1.5 Hz amplitude tremolo
    var filterCoeff: Double  = 0.252
    var envelopeGain: Double = 0.0
    var envelopeState: Int   = 0       // 0 idle · 1 attack · 2 sustain · 3 release
}

actor DroneEngine {
    private let synthState = SynthState()
    private var sourceNode: AVAudioSourceNode?
    private var isSetUp = false

    // MARK: – Setup

    func setup() async throws {
        let audioService = AudioEngineService.shared
        let sr = await audioService.sampleRate

        synthState.sampleRate        = sr
        synthState.attackIncrement   = 1.0 / (0.05 * sr)
        synthState.releaseIncrement  = 1.0 / (0.05 * sr)
        synthState.filterCoeff       = 1.0 - exp(-2 * .pi * 2_000.0 / sr)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)
        else { return }

        let state = synthState

        let node = AVAudioSourceNode(format: format) { isSilence, _, frameCount, audioBufferList in
            guard state.isRunning || state.envelopeState == 3 else {
                isSilence.pointee = true
                return noErr
            }

            guard
                let channelData = UnsafeMutableAudioBufferListPointer(audioBufferList)
                    .first?.mData?.assumingMemoryBound(to: Float.self)
            else { return noErr }

            let count = state.frequencyCount
            let vol   = Double(state.volume)
            let wf    = state.waveformRaw
            let sr    = state.sampleRate
            let fc    = state.filterCoeff

            for i in 0..<Int(frameCount) {

                if state.wantRelease && state.envelopeState == 2 {
                    state.envelopeState = 3
                    state.wantRelease   = false
                }

                // Envelope
                switch state.envelopeState {
                case 1:
                    state.envelopeGain += state.attackIncrement
                    if state.envelopeGain >= 1.0 { state.envelopeGain = 1.0; state.envelopeState = 2 }
                case 3:
                    state.envelopeGain -= state.releaseIncrement
                    if state.envelopeGain <= 0.0 {
                        state.envelopeGain  = 0.0
                        state.envelopeState = 0
                        state.isRunning     = false
                        memset(channelData + i, 0, (Int(frameCount) - i) * MemoryLayout<Float>.size)
                        return noErr
                    }
                default: break
                }

                // LFO — vibrato for strings (5 Hz, ±0.5 % pitch)
                let vibrato: Double
                if wf == 1 {
                    state.lfoVibratoPhase = (state.lfoVibratoPhase + 5.0 / sr)
                        .truncatingRemainder(dividingBy: 1.0)
                    vibrato = sin(2 * .pi * state.lfoVibratoPhase) * 0.005
                } else {
                    vibrato = 0.0
                }

                // LFO — tremolo for organ (1.5 Hz amplitude modulation, ±20 %)
                let tremolo: Double
                if wf == 0 {
                    state.lfoTremoloPhase = (state.lfoTremoloPhase + 1.5 / sr)
                        .truncatingRemainder(dividingBy: 1.0)
                    tremolo = 1.0 + 0.20 * sin(2 * .pi * state.lfoTremoloPhase)
                } else {
                    tremolo = 1.0
                }

                // Sum all active frequencies
                var sum: Double = 0.0
                for j in 0..<count {
                    let ef = state.frequencies[j] * (1.0 + vibrato)
                    state.phases[j] = (state.phases[j] + ef / sr)
                        .truncatingRemainder(dividingBy: 1.0)
                    let (s, fs) = DroneEngine.waveformSample(
                        wf: wf, phase: state.phases[j],
                        filterState: state.filterStates[j], fc: fc
                    )
                    state.filterStates[j] = fs
                    sum += s
                }

                let mixed = (sum / Double(count)) * tremolo
                channelData[i] = Float(mixed * vol * state.envelopeGain)
            }
            return noErr
        }

        await audioService.attachAndConnect(node, format: format)
        sourceNode = node
        isSetUp = true
    }

    // MARK: – Control

    func start(config: DroneConfiguration) {
        guard isSetUp else { return }
        applyConfig(config)
        if !synthState.isRunning {
            synthState.envelopeState = 1
            synthState.isRunning     = true
        }
    }

    func stop() {
        guard synthState.isRunning else { return }
        synthState.wantRelease = true
    }

    func updateConfiguration(_ config: DroneConfiguration) {
        applyConfig(config)
    }

    // MARK: – Helpers

    private func applyConfig(_ config: DroneConfiguration) {
        let baseFreq = config.frequency(for: config.key, octave: config.octave)

        // Build sorted list of active intervals for deterministic ordering
        let ordered: [DroneInterval] = [.root, .third, .fourth, .fifth, .seventh]
        let active = ordered.filter { config.activeIntervals.contains($0) }

        synthState.frequencyCount = active.count
        for (i, interval) in active.enumerated() {
            let st = interval.semitones(for: config.scaleMode)
            synthState.frequencies[i] = baseFreq * pow(2.0, Double(st) / 12.0)
        }

        synthState.volume      = config.volume
        synthState.waveformRaw = Self.waveformIndex(config.waveform)
    }

    private static func waveformIndex(_ waveform: Waveform) -> Int {
        switch waveform {
        case .organ:   0
        case .strings: 1
        }
    }

    nonisolated private static func waveformSample(
        wf: Int,
        phase: Double,
        filterState: Double,
        fc: Double
    ) -> (Double, Double) {
        switch wf {
        case 0:  // Organ — 4 additive harmonics (Hammond-style)
            let s = (
                sin(2 * .pi * phase)             +
                sin(2 * .pi * phase * 2) * 0.500 +
                sin(2 * .pi * phase * 3) * 0.250 +
                sin(2 * .pi * phase * 4) * 0.125
            ) / 1.875
            return (s, filterState)

        default:  // Strings — 4-harmonic sawtooth + first-order IIR low-pass
            let saw = (
                sin(2 * .pi * phase)             +
                sin(2 * .pi * phase * 2) * 0.500 +
                sin(2 * .pi * phase * 3) * 0.333 +
                sin(2 * .pi * phase * 4) * 0.250
            ) / 2.083
            let newState = fc * saw + (1.0 - fc) * filterState
            return (newState, newState)
        }
    }
}
