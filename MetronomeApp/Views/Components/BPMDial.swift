import SwiftUI

struct BPMDial: View {
    let bpm: BPM
    let onBPMChanged: (BPM) -> Void

    @State private var dragStartBPM: Double? = nil
    @State private var isDragging = false

    private let dialSize: CGFloat = 240
    private let sensitivity: Double = 0.4

    var body: some View {
        ZStack {
            DialTrack(fraction: 1.0)
                .stroke(.quaternary, style: StrokeStyle(lineWidth: 14, lineCap: .round))

            DialTrack(fraction: max(normalizedBPM, 0.001))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))

            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                .frame(width: 20, height: 20)
                .position(handlePosition)

            VStack(spacing: 2) {
                Text(bpm.description)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("BPM")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
        }
        .frame(width: dialSize, height: dialSize)
        .scaleEffect(isDragging ? 1.03 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if dragStartBPM == nil {
                        dragStartBPM = bpm.rawValue
                        isDragging = true
                    }
                    let delta = -value.translation.height
                    let newRaw = (dragStartBPM ?? bpm.rawValue) + delta * sensitivity
                    onBPMChanged(BPM(rawValue: newRaw))
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

    private var handlePosition: CGPoint {
        let angle = Angle.degrees(135 + normalizedBPM * 270)
        let radius = dialSize / 2 - 7
        return CGPoint(
            x: dialSize / 2 + radius * cos(angle.radians),
            y: dialSize / 2 + radius * sin(angle.radians)
        )
    }
}

private struct DialTrack: Shape {
    var fraction: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 7
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(135),
            endAngle: .degrees(135 + 270 * fraction),
            clockwise: false
        )
        return path
    }
}

#Preview {
    BPMDial(bpm: BPM(rawValue: 120)) { _ in }
        .padding()
}
