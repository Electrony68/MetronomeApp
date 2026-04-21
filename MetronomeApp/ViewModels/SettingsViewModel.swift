import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: – Publikt tillstånd
    var presets: [Preset]  = []
    var errorMessage: String? = nil

    // MARK: – Setup

    func setup() async {
        await loadPresets()
    }

    // MARK: – Preset-hantering

    func loadPresets() async {
        presets = (try? await PersistenceService.shared.loadPresets()) ?? []
    }

    func addPreset(name: String, metronome: MetronomeSettings, drone: DroneConfiguration) async {
        let preset = Preset(name: name, metronome: metronome, drone: drone)
        do {
            try await PersistenceService.shared.addPreset(preset)
            presets.append(preset)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deletePreset(id: UUID) async {
        do {
            try await PersistenceService.shared.deletePreset(id: id)
            presets.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updatePreset(_ preset: Preset) async {
        do {
            try await PersistenceService.shared.updatePreset(preset)
            if let idx = presets.firstIndex(where: { $0.id == preset.id }) {
                presets[idx] = preset
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Sparar aktuellt metronom- och drone-läge som ett nytt preset.
    func saveCurrentAsPreset(
        name: String,
        metronomeVM: MetronomeViewModel,
        droneVM: DroneViewModel
    ) async {
        let metronomeSettings = MetronomeSettings(
            bpm: metronomeVM.bpm,
            timeSignature: metronomeVM.timeSignature,
            accentPattern: metronomeVM.accentPattern,
            metronomeVolume: metronomeVM.metronomeVolume,
            droneVolume: droneVM.configuration.volume,
            mixWithOthers: metronomeVM.mixWithOthers,
            autoAccelerate: metronomeVM.autoAccelerateSettings
        )
        await addPreset(name: name, metronome: metronomeSettings, drone: droneVM.configuration)
    }

    // Laddar ett preset och applicerar det på MetronomeViewModel och DroneViewModel.
    func applyPreset(_ preset: Preset, metronomeVM: MetronomeViewModel, droneVM: DroneViewModel) async {
        let m = preset.metronome
        metronomeVM.bpm                    = m.bpm
        metronomeVM.timeSignature          = m.timeSignature
        metronomeVM.accentPattern          = m.accentPattern
        metronomeVM.metronomeVolume        = m.metronomeVolume
        metronomeVM.mixWithOthers          = m.mixWithOthers
        metronomeVM.autoAccelerateSettings = m.autoAccelerate

        if metronomeVM.isPlaying {
            await metronomeVM.setTimeSignature(m.timeSignature)
            await metronomeVM.setAccentPattern(m.accentPattern)
            await metronomeVM.setVolume(m.metronomeVolume)
            metronomeVM.setBPM(m.bpm)
        }

        await droneVM.applyConfiguration(preset.drone)
    }
}
