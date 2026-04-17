import SwiftUI

struct ContentView: View {
    @StateObject private var modeManager = MusicModeManager.shared
    @StateObject private var workoutsMode = WorkoutsModeManager.shared
    @StateObject private var workspaceMode = WorkspaceModeManager.shared

    var body: some View {
        if modeManager.isMusicModeEnabled {
            MusicTabView()
        } else if workoutsMode.isWorkoutsModeEnabled {
            WorkoutsHomeView()
        } else if workspaceMode.isWorkspaceModeEnabled {
            WorkspaceHomeView()
        } else {
            DashboardView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Music Tab Bar

struct MusicTabView: View {
    @State private var selectedTab: MusicAppTab = .home

    enum MusicAppTab: String, CaseIterable {
        case home    = "Home"
        case library = "Library"
        case radio   = "Radio"

        var icon: String {
            switch self {
            case .home:    return "house.fill"
            case .library: return "music.note.list"
            case .radio:   return "antenna.radiowaves.left.and.right"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MusicHomeView()
                .tabItem { Label(MusicAppTab.home.rawValue, systemImage: MusicAppTab.home.icon) }
                .tag(MusicAppTab.home)

            MusicLibraryView()
                .tabItem { Label(MusicAppTab.library.rawValue, systemImage: MusicAppTab.library.icon) }
                .tag(MusicAppTab.library)

            RadioView()
                .tabItem { Label(MusicAppTab.radio.rawValue, systemImage: MusicAppTab.radio.icon) }
                .tag(MusicAppTab.radio)
        }
    }
}

#Preview {
    ContentView()
}
