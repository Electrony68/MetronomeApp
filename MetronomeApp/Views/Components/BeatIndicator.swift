import SwiftUI

struct BeatIndicator: View {
    let beatCount: Int
    let currentBeat: Int
    let accentPattern: AccentPattern
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<beatCount, id: \.self) { index in
                let accent = accentPattern.beats.indices.contains(index)
                    ? accentPattern.beats[index]
                    : AccentLevel.medium
                BeatDot(
                    index: index,
                    currentBeat: currentBeat,
                    accent: accent,
                    isPlaying: isPlaying
                )
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Beat indicator")
        .accessibilityValue(isPlaying ? "Beat \(currentBeat + 1) of \(beatCount)" : "Stopped")
    }
}

private struct BeatDot: View {
    let index: Int
    let currentBeat: Int
    let accent: AccentLevel
    let isPlaying: Bool

    @State private var scale: CGFloat = 1.0

    private var isActive: Bool { isPlaying && currentBeat == index }

    var body: some View {
        Circle()
            .fill(isActive ? accent.dotColor : Color.beatInactive)
            .frame(width: 28, height: 28)
            .scaleEffect(scale)
            .shadow(color: isActive ? accent.dotColor.opacity(0.5) : .clear, radius: 8)
            .animation(.easeOut(duration: 0.15), value: isActive)
            .onChange(of: currentBeat) { _, newBeat in
                guard isPlaying, newBeat == index else { return }
                withAnimation(.easeOut(duration: 0.04)) { scale = 1.5 }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(80))
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { scale = 1.0 }
                }
            }
            .onChange(of: isPlaying) { _, playing in
                if !playing { scale = 1.0 }
            }
    }
}

private extension AccentLevel {
    var dotColor: Color {
        switch self {
        case .strong: .accentStrong
        case .medium: .accentMedium
        case .weak:   .accentWeak
        case .off:    .beatInactive
        }
    }
}

#Preview {
    let pattern = AccentPattern(beats: [.strong, .medium, .medium, .medium])
    BeatIndicator(beatCount: 4, currentBeat: 0, accentPattern: pattern, isPlaying: false)
        .padding()
}
