import SwiftUI

struct ContentView: View {
    @StateObject private var modeManager = MusicModeManager.shared

    var body: some View {
        if modeManager.isMusicModeEnabled {
            MusicLibraryView()
        } else {
            DashboardView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
