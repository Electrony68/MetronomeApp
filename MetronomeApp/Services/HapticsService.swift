import UIKit

@MainActor
final class HapticsService {
    static let shared = HapticsService()

    private let light  = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy  = UIImpactFeedbackGenerator(style: .heavy)

    private init() {}

    func prepare() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        light.prepare()
        medium.prepare()
        heavy.prepare()
    }

    func impact(for accentLevel: AccentLevel) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        switch accentLevel {
        case .off:    break
        case .weak:   light.impactOccurred()
        case .medium: medium.impactOccurred()
        case .strong: heavy.impactOccurred()
        }
    }
}
