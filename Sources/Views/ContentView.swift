import SwiftUI

struct ContentView: View {
    @StateObject private var modeManager = MusicModeManager.shared
    @StateObject private var workoutsMode = WorkoutsModeManager.shared
    @StateObject private var workspaceMode = WorkspaceModeManager.shared
    @State private var isAuthenticated = false
    @State private var isCheckingSession = true
    @State private var hasRestoredSession = false

    var body: some View {
        Group {
            if isCheckingSession {
                ProgressView("Checking session...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isAuthenticated {
                authenticatedContent
            } else {
                LoginView {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        isAuthenticated = true
                    }
                }
            }
        }
        .task {
            await restoreSessionIfNeeded()
        }
    }

    @ViewBuilder
    private var authenticatedContent: some View {
        if modeManager.isMusicModeEnabled {
            MusicTabView()
        } else if workoutsMode.isWorkoutsModeEnabled {
            WorkoutsHomeView()
        } else if workspaceMode.isWorkspaceModeEnabled {
            WorkspaceHomeView()
        } else {
            DashboardView {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    isAuthenticated = false
                }
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @MainActor
    private func restoreSessionIfNeeded() async {
        guard !hasRestoredSession else { return }
        hasRestoredSession = true

        do {
            _ = try await account.get()
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }

        isCheckingSession = false
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
