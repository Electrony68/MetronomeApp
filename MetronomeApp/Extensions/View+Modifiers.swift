import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func sectionHeader() -> some View {
        self
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

struct AppButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary, destructive }

    let variant: Variant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 60, minHeight: 60)
            .background(background(configuration.isPressed))
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }

    private func background(_ pressed: Bool) -> some ShapeStyle {
        let opacity = pressed ? 0.8 : 1.0
        switch variant {
        case .primary:     return AnyShapeStyle(Color.accentColor.opacity(opacity))
        case .secondary:   return AnyShapeStyle(Color.white.opacity(pressed ? 0.14 : 0.10))
        case .destructive: return AnyShapeStyle(Color.red.opacity(opacity))
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary, .destructive: .white
        case .secondary:             .primary
        }
    }
}
