import SwiftUI

struct DroneView: View {
    @Environment(DroneViewModel.self) private var droneVM
    @State private var keyScaleExpanded = true
    @State private var soundExpanded = true
    @State private var tuningExpanded = false

    var body: some View {
        @Bindable var vm = droneVM

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Play/Stop button
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

                    // Intervals — always visible, the main musical control
                    intervalCard(vm: vm)

                    // Key & Scale
                    DisclosureGroup(isExpanded: $keyScaleExpanded) {
                        VStack(spacing: 14) {
                            keyGrid(vm: vm)
                            scaleModeRow(vm: vm)
                        }
                        .padding(.top, 10)
                    } label: {
                        Text("Key & Scale").sectionHeader()
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Sound — Waveform, Octave, Volume
                    DisclosureGroup(isExpanded: $soundExpanded) {
                        VStack(spacing: 14) {
                            waveformRow(vm: vm)
                            octaveRow(vm: vm)
                            volumeRow(
                                volume: Bindable(vm).configuration.volume,
                                onChange: { v in Task { @MainActor in await vm.setVolume(v) } }
                            )
                        }
                        .padding(.top, 10)
                    } label: {
                        Text("Sound").sectionHeader()
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Tuning — collapsed by default
                    DisclosureGroup(isExpanded: $tuningExpanded) {
                        referenceA4Row(vm: vm)
                            .padding(.top, 10)
                    } label: {
                        HStack {
                            Text("Tuning").sectionHeader()
                            Spacer()
                            if !tuningExpanded {
                                Text(String(format: "A4 = %.0f Hz", vm.configuration.referenceA4))
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(Color.coalBackground)
            .navigationTitle("Drone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.coalBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

    // MARK: - Section helpers

    private func intervalCard(vm: DroneViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intervals").sectionHeader()
            HStack(spacing: 10) {
                ForEach(DroneInterval.allCases) { interval in
                    let active = vm.configuration.activeIntervals.contains(interval)
                    Button {
                        Task { @MainActor in await vm.toggleInterval(interval) }
                    } label: {
                        Text(interval.rawValue)
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(active ? Color.accentColor : Color.white.opacity(0.08))
                            .foregroundStyle(active ? Color.white : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(interval.rawValue)
                    .accessibilityAddTraits(active ? .isSelected : [])
                }
            }
        }
        .cardStyle()
    }

    private func keyGrid(vm: DroneViewModel) -> some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 6), count: 4), spacing: 6) {
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
                                : Color.white.opacity(0.08)
                        )
                        .foregroundStyle(vm.configuration.key == key ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(vm.configuration.key == key ? .isSelected : [])
            }
        }
    }

    private func scaleModeRow(vm: DroneViewModel) -> some View {
        HStack(spacing: 6) {
            ForEach(ScaleMode.allCases) { mode in
                Button {
                    Task { @MainActor in await vm.setScaleMode(mode) }
                } label: {
                    Text(mode.rawValue)
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(vm.configuration.scaleMode == mode ? Color.accentColor : Color.white.opacity(0.08))
                        .foregroundStyle(vm.configuration.scaleMode == mode ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(vm.configuration.scaleMode == mode ? .isSelected : [])
            }
        }
    }

    private func waveformRow(vm: DroneViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Waveform")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(Waveform.allCases) { wf in
                    Button {
                        Task { @MainActor in await vm.setWaveform(wf) }
                    } label: {
                        Text(wf.localizedName)
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(vm.configuration.waveform == wf ? Color.accentColor : Color.white.opacity(0.08))
                            .foregroundStyle(vm.configuration.waveform == wf ? Color.white : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(vm.configuration.waveform == wf ? .isSelected : [])
                }
            }
        }
    }

    private func octaveRow(vm: DroneViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Octave")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(Octave.allCases) { oct in
                    Button {
                        Task { @MainActor in await vm.setOctave(oct) }
                    } label: {
                        Text(oct.localizedName)
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(vm.configuration.octave == oct ? Color.accentColor : Color.white.opacity(0.08))
                            .foregroundStyle(vm.configuration.octave == oct ? Color.white : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(vm.configuration.octave == oct ? .isSelected : [])
                }
            }
        }
    }

    private func volumeRow(volume: Binding<Float>, onChange: @escaping (Float) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Volume")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            HStack {
                Image(systemName: "speaker").foregroundStyle(.secondary)
                Slider(value: volume, in: 0...1)
                    .onChange(of: volume.wrappedValue) { _, v in onChange(v) }
                Image(systemName: "speaker.wave.3").foregroundStyle(.secondary)
            }
        }
    }

    private func referenceA4Row(vm: DroneViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reference A4")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
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
    }
}

#Preview {
    DroneView()
        .environment(DroneViewModel())
}
