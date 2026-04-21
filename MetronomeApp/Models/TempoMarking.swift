import Foundation

/// Traditionella tempobenämningar med tillhörande BPM-intervall.
enum TempoMarking: String, CaseIterable, Sendable {
    case larghissimo = "Larghissimo"
    case largo       = "Largo"
    case larghetto   = "Larghetto"
    case adagio      = "Adagio"
    case andante     = "Andante"
    case moderato    = "Moderato"
    case allegretto  = "Allegretto"
    case allegro     = "Allegro"
    case vivace      = "Vivace"
    case presto      = "Presto"
    case prestissimo = "Prestissimo"

    var bpmRange: Range<Double> {
        switch self {
        case .larghissimo: 0..<24
        case .largo:       24..<56
        case .larghetto:   56..<66
        case .adagio:      66..<76
        case .andante:     76..<108
        case .moderato:    108..<120
        case .allegretto:  120..<132
        case .allegro:     132..<168
        case .vivace:      168..<176
        case .presto:      176..<200
        case .prestissimo: 200..<Double.infinity
        }
    }

    init(bpm: BPM) {
        self = TempoMarking.allCases.first { $0.bpmRange.contains(bpm.rawValue) } ?? .moderato
    }
}
