import SwiftUI

struct PresetListView: View {
    @Environment(MetronomeViewModel.self) private var metronomeVM
    @Environment(DroneViewModel.self) private var droneVM
    @Environment(SettingsViewModel.self) private var settingsVM

    @State private var showSaveSheet = false
    @State private var newPresetName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Presets")
                    .sectionHeader()
                Spacer()
                Button {
                    showSaveSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Save new preset")
            }

            if settingsVM.presets.isEmpty {
                Text("No presets saved yet.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ForEach(settingsVM.presets) { preset in
                    presetRow(preset)
                    Divider()
                }
            }
        }
        .sheet(isPresented: $showSaveSheet) {
            saveSheet
        }
    }

    private func presetRow(_ preset: Preset) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text("\(preset.metronome.bpm.description) BPM · \(preset.metronome.timeSignature.rawValue) · \(preset.drone.key.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { @MainActor in
                    await settingsVM.applyPreset(
                        preset,
                        metronomeVM: metronomeVM,
                        droneVM: droneVM
                    )
                }
            } label: {
                Text("Load")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { @MainActor in
                    await settingsVM.deletePreset(id: preset.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var saveSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $newPresetName)
                        .autocorrectionDisabled()
                } header: {
                    Text("Preset Name")
                }
            }
            .navigationTitle("Save Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSaveSheet = false
                        newPresetName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let name = newPresetName.trimmingCharacters(in: .whitespaces)
                        Task { @MainActor in
                            await settingsVM.saveCurrentAsPreset(
                                name: name.isEmpty ? "Preset" : name,
                                metronomeVM: metronomeVM,
                                droneVM: droneVM
                            )
                        }
                        showSaveSheet = false
                        newPresetName = ""
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
