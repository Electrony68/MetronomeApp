import SwiftUI

struct BPMDial: View {
    let bpm: BPM
    let onBPMChanged: (BPM) -> Void

    @State private var dragStartBPM: Double? = nil
    @State private var isDragging = false

    private let dialSize: CGFloat = 360
    private let trackDiameter: CGFloat = 280
    private let trackLineWidth: CGFloat = 10
    private let tickRadius: CGFloat = 162
    private let tickCount = 60
    private let sensitivity: Double = 0.5

    var body: some View {
        ZStack {
            // Decorative tick marks around the outer ring
            ForEach(0..<tickCount, id: \.self) { i in
                let major = i % 5 == 0
                Rectangle()
                    .fill(major ? Color.white.opacity(0.40) : Color.white.opacity(0.18))
                    .frame(width: major ? 2.5 : 1.5, height: major ? 13 : 7)
                    .offset(y: -tickRadius)
                    .rotationEffect(.degrees(Double(i) / Double(tickCount) * 360))
            }

            // Track ring (full circle background)
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: trackLineWidth)
                .frame(width: trackDiameter, height: trackDiameter)

            // Progress arc (starts at top, 12 o'clock)
            Circle()
                .trim(from: 0, to: normalizedBPM)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: trackLineWidth, lineCap: .round))
                .frame(width: trackDiameter, height: trackDiameter)
                .rotationEffect(.degrees(-90))

            // BPM value in center
            VStack(spacing: 4) {
                Text(bpm.description)
                    .font(.system(size: 78, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("BPM")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.40))
                    .tracking(4)
            }
        }
        .frame(width: dialSize, height: dialSize)
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDragging)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if dragStartBPM == nil {
                        dragStartBPM = bpm.rawValue
                        isDragging = true
                    }
                    let delta = -value.translation.height
                    onBPMChanged(BPM(rawValue: (dragStartBPM ?? bpm.rawValue) + delta * sensitivity))
                }
                .onEnded { _ in
                    dragStartBPM = nil
                    isDragging = false
                }
        )
        .accessibilityElement()
        .accessibilityLabel("BPM")
        .accessibilityValue(bpm.description)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onBPMChanged(BPM(rawValue: bpm.rawValue + 1))
            case .decrement: onBPMChanged(BPM(rawValue: bpm.rawValue - 1))
            @unknown default: break
            }
        }
    }

    private var normalizedBPM: Double {
        (bpm.rawValue - BPM.range.lowerBound) / (BPM.range.upperBound - BPM.range.lowerBound)
    }
}

#Preview {
    ZStack {
        Color.coalBackground.ignoresSafeArea()
        BPMDial(bpm: BPM(rawValue: 120)) { _ in }
    }
}
