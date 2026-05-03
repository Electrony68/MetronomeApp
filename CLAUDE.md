# CLAUDE.md – MetronomeApp (Metronomy)

## Bygg och kör
```bash
open MetronomeApp.xcodeproj   # Xcode, Cmd+R för att köra, Cmd+U för tester
```
Target: fysisk iPad (iPadOS 17+). Simulatorn saknar stöd för `UIBackgroundModes = audio` och haptik.

Development-build löper ut efter 7 dagar. Återaktivera: Inställningar → Allmänt → VPN och enhetshantering → lita på certifikatet → Cmd+R.

## Nuläge
v1.1 klar — funktioner (drone-ombyggnad, intervallsystem, övningstimer) och GUI-redesign (Soundbrenner-inspirerad, mörkt tema). 44/44 tester gröna.

**Nästa:** Drone-vyn är inte helt färdig designmässigt. Utgångspunkten nästa session.

## Kritiska tekniska beslut

### MetronomeEngine timing — RÖR INTE utan att förstå detta
- Schemaläggning kräver `AVAudioTime(hostTime: mach_absolute_time())` — ALDRIG sample-domänen
- `playerNode.lastRenderTime` och `outputNode.lastRenderTime` har **olika nollpunkter** — inte utbytbara
- Look-ahead kedjedesign: beat N schemalägger beat N+2 (två parallella kedjor)
- Generations-räknare (`generation: Int`) förhindrar galopp-effekt vid BPM-byte i farten
- `.off`-slag måste schemalägga tyst buffer — callback-kedjan får aldrig brytas

### DroneEngine — flerfrekvensblandning
- `SynthState.frequencies: [Double]` (5 el.) + `frequencyCount: Int` sätts från actor-tråden
- `phases`, `filterStates`: [Double] (5 el.) — audio-thread-only, inga locks
- Normalisering: summan divideras med `frequencyCount` → konstant volym oavsett antal aktiva intervall

### Concurrency
- Audio-kod i `actor DroneEngine` / `actor MetronomeEngine`
- UI på `@MainActor`; `SynthState` är `final class @unchecked Sendable`
- Swift 6 strict concurrency aktivt (`SWIFT_VERSION = 6.0`)

### Övrigt
- pywb körs ej här — det tillhör WARC Search-projektet i `/Users/tonybaving/warc-search`
- Drone-vyn: `Bindable(vm).configuration.volume` ger `Binding<Float>` via kedjesubscript — detta är korrekt och avsiktligt
