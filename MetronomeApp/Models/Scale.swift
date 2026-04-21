import Foundation

enum MusicalKey: String, CaseIterable, Codable, Sendable, Identifiable {
    case c      = "C"
    case cSharp = "C#"
    case d      = "D"
    case dSharp = "D#"
    case e      = "E"
    case f      = "F"
    case fSharp = "F#"
    case g      = "G"
    case gSharp = "G#"
    case a      = "A"
    case aSharp = "A#"
    case b      = "B"

    var id: String { rawValue }

    /// Halvtonsavstånd från C (0) uppåt.
    var semitoneOffset: Int {
        switch self {
        case .c:      0
        case .cSharp: 1
        case .d:      2
        case .dSharp: 3
        case .e:      4
        case .f:      5
        case .fSharp: 6
        case .g:      7
        case .gSharp: 8
        case .a:      9
        case .aSharp: 10
        case .b:      11
        }
    }
}

enum ScaleMode: String, CaseIterable, Codable, Sendable, Identifiable {
    case root            = "Root"
    case major           = "Major"
    case minor           = "Minor"
    case dorian          = "Dorian"
    case mixolydian      = "Mixolydian"
    case pentatonicMajor = "Pentatonic Major"
    case pentatonicMinor = "Pentatonic Minor"

    var id: String { rawValue }

    /// Halvtonsintervall för varje skalsteg ovanför grundton.
    var intervals: [Int] {
        switch self {
        case .root:            [0]
        case .major:           [0, 2, 4, 5, 7, 9, 11]
        case .minor:           [0, 2, 3, 5, 7, 8, 10]
        case .dorian:          [0, 2, 3, 5, 7, 9, 10]
        case .mixolydian:      [0, 2, 4, 5, 7, 9, 10]
        case .pentatonicMajor: [0, 2, 4, 7, 9]
        case .pentatonicMinor: [0, 3, 5, 7, 10]
        }
    }
}

enum Octave: Int, CaseIterable, Codable, Sendable, Identifiable {
    case low    = 2
    case middle = 4
    case high   = 5

    var id: Int { rawValue }

    var localizedName: String {
        switch self {
        case .low:    String(localized: "Low",    bundle: .main)
        case .middle: String(localized: "Middle", bundle: .main)
        case .high:   String(localized: "High",   bundle: .main)
        }
    }
}
