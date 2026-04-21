import SwiftUI

struct DroneView: View {
    @Environment(DroneViewModel.self) private var droneVM

    var body: some View {
        @Bindable var vm = droneVM

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Button {
                        Task { @MainActor in await vm.togglePlayback() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: vm.isPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 22, weight: .bold))
                            Text(vm.isPlaying ? "Stop Drone" : "Start Drone")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .buttonStyle(AppButtonStyle(variant: vm.isPlaying ? .destructive : .primary))
                    .accessibilityLabel(vm.isPlaying ? "Stop drone" : "Start drone")

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 16) {
                        keyPickerCard(vm: vm)
                        scaleModeCard(vm: vm)
                        octaveCard(vm: vm)
                        intervalCard(vm: vm)
                    }

                    WaveformPicker(selection: vm.configuration.waveform) { wf in
                        Task { @MainActor in await vm.setWaveform(wf) }
                    }
                    .cardStyle()

                    VolumeSliderCard(volume: $vm.configuration.volume) { v in
                        Task { @MainActor in await vm.setVolume(v) }
                    }

                    referenceA4Card(vm: vm)
                }
                .padding()
            }
            .navigationTitle("Drone")
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private func keyPickerCard(vm: DroneViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Key")
                .sectionHeader()
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(MusicalKey.allCases) { key in
                    Button {
                        Task { @MainActor in await vm.setKey(key) }
                    } label: {
                        Text(key.rawValue)
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                vm.configuration.key == key
                                    ? Color.accentColor
                                    : Color(.tertiarySystemBackground)
                            )
                            .foregroundStyle(vm.configuration.key == key ? Color.white : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(vm.configuration.key == key ? .isSelected : [])
                }
            }
        }
        .cardStyle()
    }

    private func scaleModeCard(vm: DroneViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scale")
                .sectionHeader()
            Picker("Scale", selection: Binding(
                get: { vm.configuration.scaleMode },
                set: { mode in Task { @MainActor in await vm.setScaleMode(mode) } }
            )) {
                ForEach(ScaleMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle()
    }

    private func octaveCard(vm: DroneViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Octave")
                .sectionHeader()
            Picker("Octave", selection: Binding(
                get: { vm.configuration.octave },
                set: { oct in Task { @MainActor in await vm.setOctave(oct) } }
            )) {
                ForEach(Octave.allCases) { oct in
                    Text(oct.localizedName).tag(oct)
                }
            }
            .pickerStyle(.segmented)
        }
        .cardStyle()
    }

    private func intervalCard(vm: DroneViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interval")
                .sectionHeader()
            Picker("Interval", selection: Binding(
                get: { vm.configuration.additionalInterval },
                set: { interval in Task { @MainActor in await vm.setInterval(interval) } }
            )) {
                ForEach(DroneInterval.allCases) { interval in
                    Text(interval.rawValue).tag(interval)
                }
            }
            .pickerStyle(.segmented)
        }
        .cardStyle()
    }

    private func referenceA4Card(vm: DroneViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Reference A4")
                    .sectionHeader()
                Spacer()
                Text(String(format: "%.0f Hz", vm.configuration.referenceA4))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(
                    get: { vm.configuration.referenceA4 },
                    set: { hz in Task { @MainActor in await vm.setReferenceA4(hz) } }
                ),
                in: DroneConfiguration.referenceRange,
                step: 1
            )
            .accessibilityLabel("Reference A4")
            .accessibilityValue(String(format: "%.0f hertz", vm.configuration.referenceA4))
        }
        .cardStyle()
    }
}

private struct VolumeSliderCard: View {
    @Binding var volume: Float
    let onChange: (Float) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Volume")
                .sectionHeader()
            HStack {
                Image(systemName: "speaker")
                    .foregroundStyle(.secondary)
                Slider(value: $volume, in: 0...1)
                    .onChange(of: volume) { _, v in onChange(v) }
                Image(systemName: "speaker.wave.3")
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

#Preview {
    DroneView()
        .environment(DroneViewModel())
}
