import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MetronomeView()
                .tabItem {
                    Label("Metronome", systemImage: "metronome")
                }

            DroneView()
                .tabItem {
                    Label("Drone", systemImage: "waveform")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(MetronomeViewModel())
        .environment(DroneViewModel())
        .environment(SettingsViewModel())
}
