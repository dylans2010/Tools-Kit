import SwiftUI

struct LMLinkMainView: View {
    @StateObject private var authManager = LMLinkAuthManager.shared
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    NavigationLink(value: LMLinkRoute.dashboard) {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                    NavigationLink(value: LMLinkRoute.devices) {
                        Label("Devices", systemImage: "desktopcomputer")
                    }
                    NavigationLink(value: LMLinkRoute.models) {
                        Label("Models", systemImage: "cpu")
                    }
                } header: {
                    Text("Main")
                }

                Section {
                    NavigationLink(value: LMLinkRoute.account) {
                        Label("Account", systemImage: "person.crop.circle")
                    }
                    NavigationLink(value: LMLinkRoute.settings) {
                        Label("Settings", systemImage: "gearshape")
                    }
                } header: {
                    Text("Preferences")
                }
            }
            .navigationTitle("LM Link")
            .navigationDestination(for: LMLinkRoute.self) { route in
                switch route {
                case .dashboard:
                    LMLinkDashboardView()
                case .devices:
                    LMLinkDevicesView()
                case .models:
                    LMLinkModelsView()
                case .account:
                    LMLinkAccountView()
                case .settings:
                    LMLinkSettingsView()
                }
            }
        }
    }
}

enum LMLinkRoute: Hashable {
    case dashboard
    case devices
    case models
    case account
    case settings
}
