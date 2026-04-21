import SwiftUI

struct TimeSignaturePicker: View {
    let selection: TimeSignature
    let onChange: (TimeSignature) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time Signature")
                .sectionHeader()
            Picker("Time Signature", selection: Binding(
                get: { selection },
                set: { onChange($0) }
            )) {
                ForEach(TimeSignature.allCases) { ts in
                    Text(ts.rawValue).tag(ts)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    TimeSignaturePicker(selection: .fourQuarter) { _ in }
        .padding()
        .cardStyle()
}
