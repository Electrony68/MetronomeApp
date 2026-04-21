import SwiftUI

struct MetronomeView: View {
    @Environment(MetronomeViewModel.self) private var metronomeVM

    var body: some View {
        @Bindable var vm = metronomeVM

        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    BeatIndicator(
                        beatCount: vm.timeSignature.beatCount,
                        currentBeat: vm.currentBeatIndex,
                        accentPattern: vm.accentPattern,
                        isPlaying: vm.isPlaying
                    )
                    .padding(.top, 8)

                    VStack(spacing: 6) {
                        BPMDial(bpm: vm.bpm) { newBPM in
                            vm.setBPM(newBPM)
                        }
                        Text(TempoMarking(bpm: vm.bpm).rawValue)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(.secondary)
                            .animation(.easeInOut(duration: 0.3), value: TempoMarking(bpm: vm.bpm))
                    }

                    HStack(spacing: 16) {
                        Button {
                            Task { @MainActor in await vm.togglePlayback() }
                        } label: {
                            Image(systemName: vm.isPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 26, weight: .bold))
                                .frame(width: 80, height: 64)
                        }
                        .buttonStyle(AppButtonStyle(variant: .primary))
                        .accessibilityLabel(vm.isPlaying ? "Stop" : "Play")
                        .keyboardShortcut(.space, modifiers: [])

                        TapTempoButton { vm.tapTempo() }
                    }

                    // Hidden buttons for keyboard BPM control (external keyboard on iPad)
                    Group {
                        Button { vm.setBPM(BPM(rawValue: vm.bpm.rawValue + 1)) } label: { EmptyView() }
                            .keyboardShortcut(.upArrow, modifiers: [])
                        Button { vm.setBPM(BPM(rawValue: vm.bpm.rawValue - 1)) } label: { EmptyView() }
                            .keyboardShortcut(.downArrow, modifiers: [])
                        Button { vm.setBPM(BPM(rawValue: vm.bpm.rawValue + 10)) } label: { EmptyView() }
                            .keyboardShortcut(.rightArrow, modifiers: [])
                        Button { vm.setBPM(BPM(rawValue: vm.bpm.rawValue - 10)) } label: { EmptyView() }
                            .keyboardShortcut(.leftArrow, modifiers: [])
                    }
                    .opacity(0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 16) {
                        TimeSignaturePicker(selection: vm.timeSignature) { ts in
                            Task { @MainActor in await vm.setTimeSignature(ts) }
                        }
                        .cardStyle()

                        VolumeSliderCard(
                            title: "Volume",
                            volume: $vm.metronomeVolume
                        ) { v in
                            Task { @MainActor in await vm.setVolume(v) }
                        }
                    }

                    AccentPatternEditor(pattern: vm.accentPattern) { pattern in
                        Task { @MainActor in await vm.setAccentPattern(pattern) }
                    }
                    .cardStyle()
                }
                .padding()
            }
            .navigationTitle("Metronome")
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
}

private struct VolumeSliderCard: View {
    let title: String
    @Binding var volume: Float
    let onChange: (Float) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
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
    MetronomeView()
        .environment(MetronomeViewModel())
}
