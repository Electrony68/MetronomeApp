import Foundation

actor PersistenceService {
    static let shared = PersistenceService()

    private let defaults = UserDefaults.standard
    private enum Key {
        static let metronome = "metronomeSettings"
        static let drone     = "droneConfiguration"
        static let presets   = "presets"
    }

    private init() {}

    // MARK: – Metronome settings

    func saveMetronomeSettings(_ settings: MetronomeSettings) throws {
        defaults.set(try JSONEncoder().encode(settings), forKey: Key.metronome)
    }

    func loadMetronomeSettings() throws -> MetronomeSettings {
        guard let data = defaults.data(forKey: Key.metronome) else { return MetronomeSettings() }
        return try JSONDecoder().decode(MetronomeSettings.self, from: data)
    }

    // MARK: – Drone configuration

    func saveDroneConfiguration(_ config: DroneConfiguration) throws {
        defaults.set(try JSONEncoder().encode(config), forKey: Key.drone)
    }

    func loadDroneConfiguration() throws -> DroneConfiguration {
        guard let data = defaults.data(forKey: Key.drone) else { return DroneConfiguration() }
        return try JSONDecoder().decode(DroneConfiguration.self, from: data)
    }

    // MARK: – Presets

    func loadPresets() throws -> [Preset] {
        guard let data = defaults.data(forKey: Key.presets) else { return [] }
        return try JSONDecoder().decode([Preset].self, from: data)
    }

    func savePresets(_ presets: [Preset]) throws {
        defaults.set(try JSONEncoder().encode(presets), forKey: Key.presets)
    }

    func addPreset(_ preset: Preset) throws {
        var list = (try? loadPresets()) ?? []
        list.append(preset)
        try savePresets(list)
    }

    func deletePreset(id: UUID) throws {
        var list = (try? loadPresets()) ?? []
        list.removeAll { $0.id == id }
        try savePresets(list)
    }

    func updatePreset(_ preset: Preset) throws {
        var list = (try? loadPresets()) ?? []
        guard let idx = list.firstIndex(where: { $0.id == preset.id }) else { return }
        list[idx] = preset
        try savePresets(list)
    }
}
