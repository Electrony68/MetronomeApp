import SwiftUI

struct WaveformPicker: View {
    let selection: Waveform
    let onChange: (Waveform) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Waveform")
                .sectionHeader()
            Picker("Waveform", selection: Binding(
                get: { selection },
                set: { onChange($0) }
            )) {
                ForEach(Waveform.allCases) { wf in
                    Label(wf.localizedName, systemImage: wf.systemImage).tag(wf)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private extension Waveform {
    var systemImage: String {
        switch self {
        case .sine:    "waveform.path"
        case .organ:   "music.note"
        case .strings: "hifispeaker"
        }
    }
}

#Preview {
    WaveformPicker(selection: .sine) { _ in }
        .padding()
        .cardStyle()
}
