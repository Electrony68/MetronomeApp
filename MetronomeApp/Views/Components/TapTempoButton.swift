import SwiftUI

struct TapTempoButton: View {
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            onTap()
            flash()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 22, weight: .medium))
                Text("Tap")
                    .font(.caption.weight(.semibold))
            }
            .frame(width: 72, height: 64)
        }
        .buttonStyle(AppButtonStyle(variant: .secondary))
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        .accessibilityLabel("Tap tempo")
        .accessibilityHint("Tap repeatedly to set BPM")
        .keyboardShortcut("t", modifiers: [])
    }

    private func flash() {
        isPressed = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            isPressed = false
        }
    }
}

#Preview {
    TapTempoButton { }
        .padding()
}
