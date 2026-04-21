import Foundation

enum TimeSignature: String, CaseIterable, Codable, Sendable, Identifiable {
    case threeQuarter  = "3/4"
    case fourQuarter   = "4/4"
    case fiveQuarter   = "5/4"
    case sixEighth     = "6/8"
    case sevenQuarter  = "7/4"

    var id: String { rawValue }

    var numerator: Int {
        switch self {
        case .threeQuarter:  3
        case .fourQuarter:   4
        case .fiveQuarter:   5
        case .sixEighth:     6
        case .sevenQuarter:  7
        }
    }

    var denominator: Int {
        switch self {
        case .sixEighth: 8
        default:         4
        }
    }

    var beatCount: Int { numerator }

    /// Multiplikator för slaglängd relativt kvartsnot.
    /// 6/8 är sammansatt takt – dotted quarter = 2/3 av ett slag.
    var beatMultiplier: Double {
        switch self {
        case .sixEighth: 2.0 / 3.0
        default:         1.0
        }
    }
}
