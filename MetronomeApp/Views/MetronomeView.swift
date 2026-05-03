import SwiftUI

struct MetronomeView: View {
    @Environment(MetronomeViewModel.self) private var metronomeVM
    @State private var showAccentPattern = false
    @State private var showTimer = false
    @State private var showVolume = false

    var body: some View {
        @Bindable var vm = metronomeVM

        ZStack {
            Color.coalBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topControlBar(vm: vm)
                    .padding(.horizontal, 28)
                    .padding(.top, 16)

                BeatIndicator(
                    beatCount: vm.timeSignature.beatCount,
                    currentBeat: vm.currentBeatIndex,
                    accentPattern: vm.accentPattern,
                    isPlaying: vm.isPlaying
                )
                .padding(.vertical, 20)

                Spacer()

                // Hero: BPM dial + tempo marking
                VStack(spacing: 12) {
                    BPMDial(bpm: vm.bpm) { newBPM in vm.setBPM(newBPM) }

                    Text(TempoMarking(bpm: vm.bpm).rawValue)
                        .font(.system(.callout, design: .serif))
                        .italic()
                        .foregroundStyle(.white.opacity(0.45))
                        .animation(.easeInOut(duration: 0.3), value: TempoMarking(bpm: vm.bpm))
                }

                Spacer()

                bottomBar(vm: vm)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 40)
            }
        }
        // Invisible keyboard shortcuts
        .overlay(alignment: .topLeading) {
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
        }
        .sheet(isPresented: $showAccentPattern) {
            accentSheet(vm: vm)
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func topControlBar(vm: MetronomeViewModel) -> some View {
        HStack(spacing: 12) {
            // Compact time signature selector
            HStack(spacing: 6) {
                ForEach(TimeSignature.allCases) { ts in
                    Button {
                        Task { @MainActor in await vm.setTimeSignature(ts) }
                    } label: {
                        Text(ts.rawValue)
                            .font(.system(.callout, design: .rounded, weight: .semibold))
                            .foregroundStyle(vm.timeSignature == ts ? .white : .white.opacity(0.40))
                            .frame(width: 48, height: 34)
                            .background(
                                vm.timeSignature == ts
                                    ? Color.accentColor.opacity(0.85)
                                    : Color.white.opacity(0.08)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Time signature \(ts.rawValue)")
                    .accessibilityAddTraits(vm.timeSignature == ts ? .isSelected : [])
                }
            }

            Spacer()

            // Practice timer
            Button { showTimer.toggle() } label: {
                Image(systemName: "timer")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(vm.practiceTimerMinutes > 0 ? Color.accentColor : .white.opacity(0.50))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .popover(isPresented: $showTimer) {
                timerPopover(vm: vm)
            }

            // Volume
            Button { showVolume.toggle() } label: {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.50))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .popover(isPresented: $showVolume) {
                volumePopover(vm: vm)
            }

            // Accent pattern
            Button { showAccentPattern = true } label: {
                Image(systemName: "waveform.path")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.50))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }

    @ViewBuilder
    private func bottomBar(vm: MetronomeViewModel) -> some View {
        HStack {
            Button {
                Task { @MainActor in await vm.togglePlayback() }
            } label: {
                Image(systemName: vm.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .frame(width: 80, height: 80)
            }
            .buttonStyle(AppButtonStyle(variant: .primary))
            .accessibilityLabel(vm.isPlaying ? "Stop" : "Play")
            .keyboardShortcut(.space, modifiers: [])

            Spacer()

            TapTempoButton { vm.tapTempo() }
        }
    }

    // MARK: - Popovers & Sheets

    @ViewBuilder
    private func timerPopover(vm: MetronomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Practice Timer")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 16) {
                Text(vm.practiceTimerMinutes == 0 ? "Off" : "\(vm.practiceTimerMinutes) min")
                    .font(.body.monospacedDigit())
                    .frame(minWidth: 64, alignment: .leading)
                Stepper(
                    "",
                    value: Binding(
                        get: { vm.practiceTimerMinutes },
                        set: { vm.setTimer(minutes: $0) }
                    ),
                    in: 0...60
                )
            }

            if vm.isPlaying && vm.practiceTimerMinutes > 0 {
                let m = vm.timerRemainingSeconds / 60
                let s = vm.timerRemainingSeconds % 60
                Text(String(format: "%d:%02d remaining", m, s))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(20)
        .frame(minWidth: 240)
        .presentationCompactAdaptation(.popover)
    }

    @ViewBuilder
    private func volumePopover(vm: MetronomeViewModel) -> some View {
        let bindable = Bindable(vm)
        VStack(alignment: .leading, spacing: 12) {
            Text("Volume")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                Image(systemName: "speaker")
                    .foregroundStyle(.secondary)
                Slider(value: bindable.metronomeVolume, in: 0...1)
                    .onChange(of: vm.metronomeVolume) { _, v in
                        Task { @MainActor in await vm.setVolume(v) }
                    }
                Image(systemName: "speaker.wave.3")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(minWidth: 240)
        .presentationCompactAdaptation(.popover)
    }

    @ViewBuilder
    private func accentSheet(vm: MetronomeViewModel) -> some View {
        NavigationStack {
            VStack(alignment: .leading) {
                AccentPatternEditor(pattern: vm.accentPattern) { pattern in
                    Task { @MainActor in await vm.setAccentPattern(pattern) }
                }
                .padding()
                Spacer()
            }
            .navigationTitle("Accent Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showAccentPattern = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    MetronomeView()
        .environment(MetronomeViewModel())
}
