import SwiftUI

struct AFMMainView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    NavigationLink(value: AFMRoute.dashboard) {
                        Label("Dashboard", systemImage: "sparkles")
                    }
                    NavigationLink(value: AFMRoute.tasks) {
                        Label("Tasks", systemImage: "list.bullet.clipboard")
                    }
                } header: {
                    Text("Overview")
                }

                Section {
                    NavigationLink(value: AFMRoute.settings) {
                        Label("Settings", systemImage: "gearshape")
                    }
                } header: {
                    Text("Preferences")
                }
            }
            .navigationTitle("AFM")
            .navigationDestination(for: AFMRoute.self) { route in
                switch route {
                case .dashboard:
                    AFMDashboardView()
                case .tasks:
                    AFMTaskView()
                case .settings:
                    AFMSettingsView()
                }
            }
        }
    }
}

enum AFMRoute: Hashable {
    case dashboard
    case tasks
    case settings
}
