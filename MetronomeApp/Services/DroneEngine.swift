@preconcurrency import AVFoundation
import Darwin

// State shared between the actor and the lock-free audio-thread render callback.
// All properties marked nonisolated(unsafe) are written from the actor and
// read on the audio thread; simple scalar types on ARM64 are written atomically.
// Properties without the annotation are only ever touched inside the render callback.
private final class SynthState: @unchecked Sendable {

    // --- Parameters (actor ↔ audio thread) ---
    nonisolated(unsafe) var isRunning: Bool   = false
    nonisolated(unsafe) var wantRelease: Bool = false

    nonisolated(unsafe) var frequency1: Double = 440.0
    nonisolated(unsafe) var frequency2: Double = 440.0
    nonisolated(unsafe) var hasInterval: Bool  = false

    nonisolated(unsafe) var volume: Float  = 0.7
    nonisolated(unsafe) var waveformRaw: Int = 0   // 0 = sine, 1 = organ, 2 = strings

    nonisolated(unsafe) var sampleRate: Double = 44_100.0
    nonisolated(unsafe) var attackIncrement: Double  = 1.0 / 2_205.0   // 50 ms
    nonisolated(unsafe) var releaseIncrement: Double = 1.0 / 2_205.0

    // --- Audio-thread-only synthesis state ---
    var phase1: Double       = 0.0
    var phase2: Double       = 0.0
    var lfoPhase: Double     = 0.0
    var filterState1: Double = 0.0
    var filterState2: Double = 0.0
    var filterCoeff: Double  = 0.252    // 1 − exp(−2π × 2000 / 44100)
    var envelopeGain: Double = 0.0
    var envelopeState: Int   = 0        // 0 idle · 1 attack · 2 sustain · 3 release
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
            // ── Audio-thread render callback ─────────────────────────────────────

            guard state.isRunning || state.envelopeState == 3 else {
                isSilence.pointee = true
                return noErr
            }

            guard
                let channelData = UnsafeMutableAudioBufferListPointer(audioBufferList)
                    .first?.mData?.assumingMemoryBound(to: Float.self)
            else { return noErr }

            let f1  = state.frequency1
            let f2  = state.frequency2
            let has2 = state.hasInterval
            let vol = Double(state.volume)
            let wf  = state.waveformRaw
            let sr  = state.sampleRate
            let fc  = state.filterCoeff

            for i in 0..<Int(frameCount) {

                // Release trigger (written from actor, read here once)
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
                        // Zero remaining frames and exit.
                        memset(channelData + i, 0, (Int(frameCount) - i) * MemoryLayout<Float>.size)
                        return noErr
                    }
                default: break
                }

                // LFO for strings vibrato (5 Hz, ±0.5 %)
                let lfoMod: Double
                if wf == 2 {
                    state.lfoPhase = (state.lfoPhase + 5.0 / sr).truncatingRemainder(dividingBy: 1.0)
                    lfoMod = sin(2 * .pi * state.lfoPhase) * 0.005
                } else {
                    lfoMod = 0.0
                }

                // ── Tone 1 ──
                let ef1 = f1 * (1.0 + lfoMod)
                state.phase1 = (state.phase1 + ef1 / sr).truncatingRemainder(dividingBy: 1.0)
                let (s1, fs1) = DroneEngine.waveformSample(
                    wf: wf, phase: state.phase1,
                    filterState: state.filterState1, fc: fc
                )
                state.filterState1 = fs1

                // ── Tone 2 (interval, optional) ──
                let mixed: Double
                if has2 {
                    let ef2 = f2 * (1.0 + lfoMod)
                    state.phase2 = (state.phase2 + ef2 / sr).truncatingRemainder(dividingBy: 1.0)
                    let (s2, fs2) = DroneEngine.waveformSample(
                        wf: wf, phase: state.phase2,
                        filterState: state.filterState2, fc: fc
                    )
                    state.filterState2 = fs2
                    mixed = (s1 + s2) * 0.5
                } else {
                    mixed = s1
                }

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
            synthState.envelopeState = 1   // begin attack
            synthState.isRunning     = true
        }
    }

    func stop() {
        guard synthState.isRunning else { return }
        synthState.wantRelease = true   // render callback fades out
    }

    func updateConfiguration(_ config: DroneConfiguration) {
        applyConfig(config)
    }

    // MARK: – Helpers

    private func applyConfig(_ config: DroneConfiguration) {
        let freq1 = config.frequency(for: config.key, octave: config.octave)
        synthState.frequency1   = freq1
        synthState.volume       = config.volume
        synthState.waveformRaw  = Self.waveformIndex(config.waveform)

        if config.additionalInterval != .none {
            let st = config.additionalInterval.semitones(for: config.scaleMode)
            synthState.frequency2  = freq1 * pow(2.0, Double(st) / 12.0)
            synthState.hasInterval = true
        } else {
            synthState.hasInterval = false
        }
    }

    private static func waveformIndex(_ waveform: Waveform) -> Int {
        switch waveform {
        case .sine:    0
        case .organ:   1
        case .strings: 2
        }
    }

    // Returns (sample, newFilterState).  Avoids inout inside the render closure.
    nonisolated private static func waveformSample(
        wf: Int,
        phase: Double,
        filterState: Double,
        fc: Double
    ) -> (Double, Double) {
        switch wf {
        case 1:  // Organ — 4 additive harmonics (Hammond-style)
            let s = (
                sin(2 * .pi * phase)             +
                sin(2 * .pi * phase * 2) * 0.500 +
                sin(2 * .pi * phase * 3) * 0.250 +
                sin(2 * .pi * phase * 4) * 0.125
            ) / 1.875
            return (s, filterState)

        case 2:  // Strings — 4-harmonic sawtooth + first-order IIR low-pass
            let saw = (
                sin(2 * .pi * phase)             +
                sin(2 * .pi * phase * 2) * 0.500 +
                sin(2 * .pi * phase * 3) * 0.333 +
                sin(2 * .pi * phase * 4) * 0.250
            ) / 2.083
            let newState = fc * saw + (1.0 - fc) * filterState
            return (newState, newState)

        default:  // Sine
            return (sin(2 * .pi * phase), filterState)
        }
    }
}
