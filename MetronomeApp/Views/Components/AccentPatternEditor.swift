import SwiftUI

struct AccentPatternEditor: View {
    let pattern: AccentPattern
    let onChange: (AccentPattern) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accent Pattern")
                .sectionHeader()
            HStack(spacing: 10) {
                ForEach(Array(pattern.beats.enumerated()), id: \.offset) { index, level in
                    Button {
                        var updated = pattern
                        updated.beats[index] = level.next
                        onChange(updated)
                    } label: {
                        VStack(spacing: 5) {
                            Circle()
                                .fill(level.dotColor)
                                .frame(width: 38, height: 38)
                                .overlay {
                                    if level == .off {
                                        Image(systemName: "minus")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            Text("\(index + 1)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Beat \(index + 1)")
                    .accessibilityValue(level.localizedName)
                    .accessibilityHint("Tap to cycle accent level")
                }
                Spacer()
            }
        }
    }
}

private extension AccentLevel {
    var next: AccentLevel {
        let all = AccentLevel.allCases
        let i = all.firstIndex(of: self) ?? 0
        return all[(i + 1) % all.count]
    }

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
    let pattern = AccentPattern(beats: [.strong, .medium, .medium, .weak])
    AccentPatternEditor(pattern: pattern) { _ in }
        .padding()
        .cardStyle()
}
