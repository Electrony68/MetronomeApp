import SwiftUI

@main
struct MetronomeApp: App {
    @State private var metronomeVM = MetronomeViewModel()
    @State private var droneVM = DroneViewModel()
    @State private var settingsVM = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(metronomeVM)
                .environment(droneVM)
                .environment(settingsVM)
                .task {
                    await metronomeVM.setup()
                    await droneVM.setup()
                    await settingsVM.setup()
                }
        }
    }
}
