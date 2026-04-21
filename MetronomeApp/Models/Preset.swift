import Foundation

struct AutoAccelerateSettings: Codable, Sendable, Equatable {
    var bpmIncrement: Double = 5
    var afterBars: Int       = 4
    var targetBPM: BPM       = BPM(rawValue: 160)
}

struct MetronomeSettings: Codable, Sendable {
    var bpm: BPM                              = .default
    var timeSignature: TimeSignature          = .fourQuarter
    var accentPattern: AccentPattern          = AccentPattern.defaultPattern(for: .fourQuarter)
    var metronomeVolume: Float                = 0.8
    var droneVolume: Float                    = 0.7
    var mixWithOthers: Bool                   = false
    var autoAccelerate: AutoAccelerateSettings? = nil
}

struct Preset: Identifiable, Codable, Sendable {
    var id: UUID               = UUID()
    var name: String
    var metronome: MetronomeSettings
    var drone: DroneConfiguration
    var createdAt: Date        = Date()

    static var empty: Preset {
        Preset(name: "", metronome: MetronomeSettings(), drone: DroneConfiguration())
    }
}
