# CLAUDE.md – MetronomeApp

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
│   ├── ViewModels/ MetronomeViewModel, DroneViewModel, SettingsViewModel
│   ├── Views/      ContentView + komponenter
│   ├── Services/   AudioEngineService, MetronomeEngine, DroneEngine,
│   │               HapticsService, PersistenceService
│   └── Extensions/ Color+Theme, View+Modifiers
└── Resources/
    ├── Assets.xcassets   (AccentColor grå ~#919199, 7 namngivna färger, AppIcon)
    └── Localizable.xcstrings  (engelska)
```

## Implementeringsstatus

| Version | Innehåll | Status |
|---------|----------|--------|
| v1.0 | Projektskelett, Models, Services, ViewModels, Views, iPad-stöd, tester | ✅ Klar |
| v1.1 funktioner | Drone-ombyggnad + övningstimer | ✅ Klar |
| v1.1 GUI | Soundbrenner-inspirerad redesign | ✅ Klar |

## Versionshistorik

### v1.0
- Sample-accurate metronom (look-ahead AVAudioTime-schemaläggning)
- Realtids-dronesyntes med tre vågformer
- BPM-ratt, taktart, accentmönster, tap tempo, auto-accelerate
- Presets, persistens via UserDefaults
- Keyboard shortcuts, VoiceOver
- 41 unit tests

### v1.1 — Funktioner (2026-05-03)
**Drone:**
- `ScaleMode` reducerad till `.root`, `.major`, `.minor`
- Nytt intervallsystem: `.root`, `.third`, `.fourth`, `.fifth`, `.seventh` — alla togglebara simultant
- `DroneConfiguration.activeIntervals: Set<DroneInterval>` (ersätter `additionalInterval`)
- `DroneConfiguration.toggle(_ interval:)` — minst ett intervall alltid aktivt
- Third och Seventh skalmedvetna: minor → 3/10 halvtoner, major/root → 4/11
- Sine-vågform borttagen ur `Waveform`-enum
- `DroneEngine` blandar upp till 5 frekvenser simultant
- Organ-tremolo: LFO 1,5 Hz ±20% amplitud (rotary-speaker)
- Strings: vibrato 5 Hz ±0,5% (oförändrat)

**Metronom:**
- Övningstimer 0–60 minuter (`practiceTimerMinutes`, `timerRemainingSeconds`)
- Startar vid play, stoppar metronomen automatiskt vid 0
- UI: timer-popover (ersatt av ikonknapp i toppraden i v1.1 GUI)

**Tester:** 44/44 gröna (ScaleTests omskrivna för nytt API)

## v1.1 GUI — Soundbrenner-inspirerad redesign (2026-05-03)

**Global:**
- `preferredColorScheme(.dark)` på ContentView — hela appen är mörk
- `Color.coalBackground` (#131318) ersätter system-bakgrunder
- `AppButtonStyle(.secondary)` använder `Color.white.opacity(0.10)` i stället för tertiarySystemBackground

**BPMDial (ombyggd):**
- Full cirkel (360°) med 60 tick-marks runt kanten (major var 5:e)
- Progress-arc startar vid 12-klockan, mapping 30–300 BPM → 0–100 %
- Storlek: 360 pt, track: 280 pt (10 pt lineWidth), tick-radius: 162 pt
- Stor siffra i mitten (78 pt bold rounded), vit

**MetronomeView (fullskärm, ingen NavigationStack):**
- Topp-rad: 5 taktarts-knappar + [timer] [volume] [accent]-ikoner
- Center: BPMDial (hero) + tempo-marking under
- Botten: Play (vänster) + Tap (höger) — 80×80 knappar
- Övningstimer i popover från timer-ikonen
- Volym i popover från speaker-ikonen
- AccentPatternEditor i sheet (.medium detent) från waveform-ikonen

**DroneView (ny struktur):**
- Intervals-kort alltid synligt (main musical control)
- Key & Scale i DisclosureGroup (öppen som standard)
- Sound (Waveform, Octave, Volume) i DisclosureGroup (öppen)
- Tuning (Reference A4) i DisclosureGroup (stängd, visar Hz i etiketten)
- Coal-bakgrund via `.scrollContentBackground(.hidden)` + `.background(Color.coalBackground)`

**App-namn:** "Metronomy" (CFBundleDisplayName i Info.plist)

## Tekniska beslut

### MetronomeEngine timing — KRITISKT
- Schemaläggning sker med `AVAudioTime(hostTime: mach_absolute_time())` — ALDRIG sample-domänen
- `playerNode.lastRenderTime` och `outputNode.lastRenderTime` har **olika nollpunkter** — inte utbytbara
- Look-ahead kedjedesign: beat N:s callback schemalägger beat N+2 (två parallella kedjor)
- Generations-räknare (`generation: Int`) förhindrar galopp-effekt vid BPM-byte i farten
- `.off`-slag schemalägger tyst buffer — callback-kedjan måste aldrig brytas

### DroneEngine — flerfrekvensblandning
- `SynthState.frequencies: [Double]` (5 element), `frequencyCount: Int` — sätts från actor-tråden
- `phases`, `filterStates`: [Double] (5 el.) — audio-thread-only, ingen `nonisolated(unsafe)`
- Intervallordning i `applyConfig`: root → third → fourth → fifth → seventh (deterministisk)
- Normalisering: summan divideras med `frequencyCount` för konstant volym oavsett antal intervall

### Concurrency
- Audio-kod i `actor AudioActor` / `actor DroneEngine` / `actor MetronomeEngine`
- UI på `@MainActor`
- `SynthState` är `final class @unchecked Sendable` med `nonisolated(unsafe)` för delade parametrar

### Övrigt
- pywb körs ej här (det är WARC Search-projektet)
- Bakgrundsljud kräver fysisk iPad — simulatorn stöder inte `UIBackgroundModes = audio`
- Haptik fungerar inte i simulatorn
- Swift 6 strict concurrency påslaget (`SWIFT_VERSION = 6.0`)
- Accentfärg: grå ~#919199 (kall systemgrå, mörklägesvariant)
- `TimeSignaturePicker.swift` och `WaveformPicker.swift` borttagna (inlinades i resp. vy)

## Bygg och kör
```bash
# Öppna i Xcode
open MetronomeApp.xcodeproj

# Välj iPad som target-device, tryck Cmd+R
# Tester: Cmd+U
```

Development-signerade builds löper ut efter 7 dagar.
Återaktivera: Inställningar → Allmänt → VPN och enhetshantering → lita på certifikatet → Cmd+R i Xcode.
