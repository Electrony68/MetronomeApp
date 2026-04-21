# MetronomeApp

iPad metronome with sample-accurate timing and real-time drone synthesis.

## Features

- **Sample-accurate metronome** — look-ahead scheduling via `AVAudioTime(hostTime:)`, no timers
- **Accent patterns** — per-beat accent levels (strong / medium / weak / off) for any time signature
- **Drone synthesis** — real-time additive synthesis with three waveforms (sine, organ, strings)
- **Auto-accelerate** — gradually increase BPM over configurable bar intervals toward a target tempo
- **Tap tempo** — rolling average over up to 8 taps
- **Preset management** — save and recall metronome + drone configurations
- **Background audio** — continues playing when iPad is locked or another app is in focus
- **Keyboard shortcuts** — space (play/stop), ↑↓ (BPM ±1), ←→ (BPM ±10), T (tap tempo)

## Requirements

- iPad with iPadOS 17.0+
- Xcode 16+ with Swift 6

## Architecture

```
MetronomeApp/
├── App/          Entry point, environment injection
├── Models/       BPM, TimeSignature, AccentPattern, Scale, DroneConfiguration, Preset, TempoMarking
├── Services/     AudioEngineService, MetronomeEngine, DroneEngine, HapticsService, PersistenceService
├── ViewModels/   MetronomeViewModel, DroneViewModel, SettingsViewModel
├── Views/        ContentView (TabView), MetronomeView, DroneView, SettingsView + components
└── Extensions/   Color+Theme, View+Modifiers
```

MVVM with Swift 6 strict concurrency. Audio services run in `actor` isolation; UI runs on `@MainActor`.

## Audio Engine

### MetronomeEngine

Scheduling uses Mach host time (`mach_absolute_time()`) — the only clock domain that works reliably with `AVAudioPlayerNode.scheduleBuffer(at:)`. Sample-time domains from `playerNode` and `outputNode` have different origins and cause silent buffer drops.

Two interleaved scheduling chains (even/odd beats) run concurrently. A generation counter prevents stale callbacks from firing after `stop()` or BPM changes.

### DroneEngine

`AVAudioSourceNode` render callback on the audio thread — lock-free, no allocation, no Obj-C calls. Three waveforms:
- **Sine** — pure sinusoid
- **Organ** — additive: 4 overtones weighted to simulate pipe organ
- **Strings** — sawtooth with 4 overtones + IIR low-pass filter + slow vibrato (LFO)

## Running Tests

Add the `MetronomeAppTests/` folder to an **Unit Testing Bundle** target in Xcode, then run with ⌘U. Tests cover pure model logic (BPM clamping, tempo markings, frequency calculations, accent patterns, time signatures, scale intervals) and require no device or audio hardware.
