# MetronomeApp – Projektdokumentation

## Vad är det här?
iPad-app (iPadOS 17+) med sample-accurate metronom och realtids-dronesyntes.
Byggs i Xcode 16+ med Swift 6 (strict concurrency) och SwiftUI + @Observable.

## Teknikstack
- **Språk:** Swift 6.0, SwiftUI, Observation-ramverket
- **Audio:** AVAudioEngine, AVAudioSourceNode (ingen timer, ingen DispatchQueue för timing)
- **Persistens:** UserDefaults / SwiftData för inställningar och presets
- **Arkitektur:** MVVM – Models / ViewModels / Views / Services
- **Target:** iPadOS 17.0+, endast iPad (TARGETED_DEVICE_FAMILY = 2)
- **Bundle ID:** com.tonybaving.MetronomeApp

## Projektstruktur
```
MetronomeApp/
├── MetronomeApp.xcodeproj/
├── Info.plist                          # UIBackgroundModes = audio, alla iPad-orienteringar
├── Sources/
│   ├── App/        MetronomeApp.swift
│   ├── Models/     BPM, TimeSignature, AccentPattern, Scale, DroneConfiguration, Preset, TempoMarking
│   ├── ViewModels/ MetronomeViewModel, DroneViewModel, SettingsViewModel  (Fas 3)
│   ├── Views/      ContentView + komponenter                              (Fas 4)
│   ├── Services/   AudioEngineService, MetronomeEngine, DroneEngine,
│   │               HapticsService, PersistenceService                     (Fas 2)
│   └── Extensions/ Color+Theme, View+Modifiers
└── Resources/
    ├── Assets.xcassets   (AccentColor cyan/turkos, 7 namngivna färger, AppIcon)
    └── Localizable.xcstrings  (engelska endast)
```

## Implementeringsstatus
| Fas | Innehåll | Status |
|-----|----------|--------|
| 1 | Projektskelett + Models + Extensions + Assets | ✅ Klar |
| 2 | AudioEngineService, MetronomeEngine, DroneEngine, HapticsService, PersistenceService | ✅ Klar |
| 3 | ViewModels (MetronomeViewModel, DroneViewModel, SettingsViewModel) | ✅ Klar |
| 4 | Views & Komponenter (BPMDial, BeatIndicator, TapTempo m.fl.) | ✅ Klar |
| 5 | iPad-specifikt: keyboard shortcuts, grundläggande VoiceOver-etiketter | ✅ Klar |
| 6 | Tester, lokalisering, README | ✅ Klar |

## Tekniska beslut
- **Timing:** `scheduleBuffer(at: AVAudioTime)` med look-ahead scheduling – aldrig Timer
- **Dronesyntes:** `AVAudioSourceNode` render-callback på audio-tråden – lock-free, ingen allokering
- **Concurrency:** Audio-kod i `actor AudioActor`, UI på `@MainActor`
- **Beat-indikator:** Synkad till `AVAudioTime`, inte wall clock (CADisplayLink eller TimelineView)
- **Klick-ljud:** Genereras i kod (inte sample-filer)
- **A4-referens:** Konfigurerbar 415–446 Hz, default 440 Hz

## Fas 5 – Tekniska beslut och noteringar
- Keyboard shortcuts i `MetronomeView`: mellanslag (play/stop), ↑↓ (BPM ±1), ←→ (BPM ±10) via dolda `Button`-element med `.keyboardShortcut`; T (tap tempo) i `TapTempoButton`
- Dolda knappar: `.opacity(0).allowsHitTesting(false).accessibilityHidden(true)` — SwiftUI-idiom för tangentbordsgenvägar utan visuell effekt
- Apple Pencil-stöd utelämnat medvetet — inte relevant för use caset
- VoiceOver var redan väl täckt från Fas 4; tillagd `accessibilityLabel/Value` på Reference A4-slidern i DroneView

## Fas 4 – Tekniska beslut och noteringar
- `ContentView`: `TabView` med tre flikar (Metronome / Drone / Settings), fungerar på iPadOS 17+
- `MetronomeApp`: ViewModels skapas som `@State` i App-structen, injiceras via `.environment()`, setup körs med `.task {}`
- `BPMDial`: Arc-ratt (270°, SwiftUI `Shape`), vertikal drag-gest (`dragStartBPM` sparas vid geststart för stabil delta-beräkning), handle-position beräknas med trigonometri och `.position()`
- `BeatIndicator`: `onChange(of: currentBeat)` triggar `withAnimation` + `Task.sleep`-sekvens för attack/decay-puls
- `AccentPatternEditor`: Cyklar AccentLevel via `next`-extension (strong→medium→weak→off→strong)
- `PresetListView`: `Text("\(bpm.description)")` — använd `.description` explicit för att undvika `LocalizedStringKey appendInterpolation`-varning
- `@Bindable var vm = metronomeVM` i view body: standard-mönster för `@Observable` + `@Environment`; async setters anropas via `.onChange(of:)` + `Task { @MainActor in }`
- Verifierat: bygg utan varningar/fel i Xcode 16, Swift 6 strict concurrency
- `DroneInterval.third`: skalmedveten ters — mollters (3 halvtoner) för minor/dorian/pentatonic minor, durters (4 halvtoner) annars; beräknas i `DroneEngine.applyConfig` via `semitones(for: scaleMode)`
- Lokalisering: svenska översättningar borttagna, appen är engelska rakt igenom

## MetronomeEngine – Tekniska beslut och lärdommar

**Status: ✅ Fullt fungerande** — verifierat på fysisk iPad Air 13-inch (M4), iPadOS 18.

**Timing-domän:** Schemaläggning sker med `AVAudioTime(hostTime:)` baserat på `mach_absolute_time()`.
- `AVAudioPlayerNode.lastRenderTime` och `outputNode.lastRenderTime` har *olika nollpunkter* och är inte utbytbara för `scheduleBuffer(at:)`.
- Host time (Mach-klockan) är den enda domänen som alltid är korrekt för AVAudioEngine-schemaläggning.

**Kedjedesign (look-ahead):** `start()` förschemalagt beat 0 och beat 1. När beat N:s callback triggar schemaläggs beat N+2. Två parallella kedjor (jämna/udda) körs alltid simultant.

**Generations-räknare:** `generation` ökas vid `stop()` och `setBPM()`. Callbacks kontrollerar att deras `capturedGeneration == self.generation` — annars ignoreras de. Förhindrar galopp-effekt vid BPM-ändringar i farten.

**`.off`-slag:** Tyst buffer (noll-fylld) schemaläggs — callbacks triggas normalt och kedjan bryts aldrig. Tidigare `guard level != .off { return }` dödade kedjan.

## Fas 2 – Tekniska beslut och noteringar
- `AudioEngineService`: notification-observering via `NotificationCenter.notifications(named:)` async-stream (inte `addObserver`) — krävs för Swift 6 `sending`-compliance
- `MetronomeEngine`: look-ahead scheduling med `AVAudioPlayerNode.scheduleBuffer(at: AVAudioTime)`, pre-genererade klick-buffertar (exp. avklingssinusvåg), `AsyncStream<BeatEvent>` för UI-synk
- `DroneEngine`: `AVAudioSourceNode` render-callback, `SynthState` (final class `@unchecked Sendable`) med `nonisolated(unsafe)` för delade parametrar; 3 vågformer (sinus, orgel 4 övertoner, stråkar 4-övertoners sågtand + IIR LP-filter + vibrato)
- `HapticsService`: `@MainActor`, respekterar `UIAccessibility.isReduceMotionEnabled`
- `PersistenceService`: actor, UserDefaults + JSONEncoder/Decoder för Settings, DroneConfiguration och Presets
- VS Code SourceKit-LSP visar falska fel i AccentPattern.swift — ignorera, Xcode bygger rent

## Viktigt att veta
- Bakgrundsljud kräver fysisk iPad – simulatorn stöder inte `UIBackgroundModes = audio`
- Haptik fungerar inte i simulatorn
- Swift 6 strict concurrency är påslaget (`SWIFT_VERSION = 6.0`)
- Accentfärg: cyan/turkos (`AccentColor` i assets)
