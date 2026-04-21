import Foundation

enum Waveform: String, CaseIterable, Codable, Sendable, Identifiable {
    case sine    = "Sine"
    case organ   = "Organ"
    case strings = "Strings"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .sine:    String(localized: "Sine",    bundle: .main)
        case .organ:   String(localized: "Organ",   bundle: .main)
        case .strings: String(localized: "Strings", bundle: .main)
        }
    }
}

enum DroneInterval: String, CaseIterable, Codable, Sendable, Identifiable {
    case none   = "None"
    case third  = "Third"
    case fifth  = "Fifth"
    case octave = "Octave"

    var id: String { rawValue }

    /// Fixed semitone offset. For .third, use semitones(for:) to get scale-aware value.
    var semitones: Int {
        switch self {
        case .none:   0
        case .third:  4
        case .fifth:  7
        case .octave: 12
        }
    }

    /// Returns semitone offset adjusted for scale mode (.third adapts to major/minor).
    func semitones(for scaleMode: ScaleMode) -> Int {
        guard self == .third else { return semitones }
        let minorScales: Set<ScaleMode> = [.minor, .dorian, .pentatonicMinor]
        return minorScales.contains(scaleMode) ? 3 : 4
    }
}

struct DroneConfiguration: Codable, Sendable, Equatable {
    var key: MusicalKey        = .a
    var scaleMode: ScaleMode   = .root
    var octave: Octave         = .middle
    var waveform: Waveform     = .sine
    var additionalInterval: DroneInterval = .none
    var volume: Float          = 0.7

    /// A4-referensfrekvens, konfigurerbar 415–446 Hz.
    var referenceA4: Double    = 440.0
    static let referenceRange: ClosedRange<Double> = 415...446

    /// Beräknar frekvens (Hz) för en given ton i konfigurationen.
    /// - Parameters:
    ///   - key: Tonen att beräkna frekvens för.
    ///   - octave: Oktaven.
    func frequency(for key: MusicalKey, octave: Octave) -> Double {
        // A4 = 440 Hz, MIDI-not 69
        let semitones = Double(key.semitoneOffset - MusicalKey.a.semitoneOffset)
            + Double(octave.rawValue - 4) * 12
        return referenceA4 * pow(2.0, semitones / 12.0)
    }
}
