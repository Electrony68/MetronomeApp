import Foundation

enum Waveform: String, CaseIterable, Codable, Sendable, Identifiable {
    case organ   = "Organ"
    case strings = "Strings"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .organ:   String(localized: "Organ",   bundle: .main)
        case .strings: String(localized: "Strings", bundle: .main)
        }
    }
}

enum DroneInterval: String, CaseIterable, Codable, Sendable, Identifiable {
    case root    = "Root"
    case third   = "Third"
    case fourth  = "Fourth"
    case fifth   = "Fifth"
    case seventh = "Seventh"

    var id: String { rawValue }

    /// Halvtonsavstånd justerat för skalläge. Third och Seventh anpassas till major/minor.
    func semitones(for scaleMode: ScaleMode) -> Int {
        switch self {
        case .root:    0
        case .third:   scaleMode == .minor ? 3 : 4
        case .fourth:  5
        case .fifth:   7
        case .seventh: scaleMode == .minor ? 10 : 11
        }
    }
}

struct DroneConfiguration: Codable, Sendable, Equatable {
    var key: MusicalKey          = .a
    var scaleMode: ScaleMode     = .major
    var octave: Octave           = .middle
    var waveform: Waveform       = .organ
    var activeIntervals: Set<DroneInterval> = [.root, .fifth]
    var volume: Float            = 0.7

    /// A4-referensfrekvens, konfigurerbar 415–446 Hz.
    var referenceA4: Double      = 440.0
    static let referenceRange: ClosedRange<Double> = 415...446

    /// Beräknar frekvens (Hz) för en given ton i konfigurationen.
    func frequency(for key: MusicalKey, octave: Octave) -> Double {
        let semitones = Double(key.semitoneOffset - MusicalKey.a.semitoneOffset)
            + Double(octave.rawValue - 4) * 12
        return referenceA4 * pow(2.0, semitones / 12.0)
    }

    /// Minst ett intervall måste alltid vara aktivt.
    mutating func toggle(_ interval: DroneInterval) {
        if activeIntervals.contains(interval) {
            guard activeIntervals.count > 1 else { return }
            activeIntervals.remove(interval)
        } else {
            activeIntervals.insert(interval)
        }
    }
}
