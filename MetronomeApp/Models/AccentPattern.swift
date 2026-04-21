import Foundation

enum AccentLevel: Int, Codable, Sendable, CaseIterable, Identifiable {
    case off    = 0
    case weak   = 1
    case medium = 2
    case strong = 3

    var id: Int { rawValue }

    var localizedName: String {
        switch self {
        case .off:    String(localized: "Off",    bundle: .main)
        case .weak:   String(localized: "Weak",   bundle: .main)
        case .medium: String(localized: "Medium", bundle: .main)
        case .strong: String(localized: "Strong", bundle: .main)
        }
    }

    /// Relativ amplitud (0.0–1.0) för denna accentnivå.
    var amplitude: Float {
        switch self {
        case .off:    0.0
        case .weak:   0.4
        case .medium: 0.7
        case .strong: 1.0
        }
    }
}

struct AccentPattern: Codable, Sendable, Equatable {
    var beats: [AccentLevel]
    var name: String

    init(beats: [AccentLevel], name: String = "") {
        self.beats = beats
        self.name = name
    }

    static func defaultPattern(for timeSignature: TimeSignature) -> AccentPattern {
        var beats = Array(repeating: AccentLevel.medium, count: timeSignature.beatCount)
        if !beats.isEmpty { beats[0] = .strong }
        return AccentPattern(beats: beats)
    }
}
