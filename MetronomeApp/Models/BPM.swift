import Foundation

/// BPM-värde begränsat till 30–300.
struct BPM: Hashable, Codable, Sendable {
    static let range: ClosedRange<Double> = 30...300
    static let `default` = BPM(rawValue: 120)

    let rawValue: Double

    init(rawValue: Double) {
        self.rawValue = rawValue.clamped(to: BPM.range)
    }

    /// Varaktighet för ett slag i sekunder.
    var beatDuration: TimeInterval { 60.0 / rawValue }
}

extension BPM: CustomStringConvertible {
    var description: String { String(format: "%.0f", rawValue) }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
