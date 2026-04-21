import SwiftUI

struct SettingsView: View {
    @Environment(MetronomeViewModel.self) private var metronomeVM
    @Environment(DroneViewModel.self) private var droneVM
    @Environment(SettingsViewModel.self) private var settingsVM

    var body: some View {
        @Bindable var metVM = metronomeVM

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PresetListView()
                        .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Audio")
                            .sectionHeader()

                        Toggle("Mix with other apps", isOn: $metVM.mixWithOthers)
                            .font(.callout)
                        Text("Changes take effect after restarting the metronome.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .cardStyle()

                    if let error = settingsVM.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(error)
                                .font(.callout)
                        }
                        .foregroundStyle(.red)
                        .cardStyle()
                        .onTapGesture { settingsVM.errorMessage = nil }
                    }
                }
                .padding()
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environment(MetronomeViewModel())
        .environment(DroneViewModel())
        .environment(SettingsViewModel())
}
