import SwiftUI

struct LMLinkMainView: View {
    @StateObject private var authManager = LMLinkAuthManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LMLinkDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            LMLinkDevicesView()
                .tabItem {
                    Label("Devices", systemImage: "desktopcomputer")
                }
                .tag(1)

            LMLinkModelsView()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
                .tag(2)

            LMLinkAccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
                .tag(3)

            LMLinkSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .navigationTitle("LM Link")
        .navigationBarTitleDisplayMode(.inline)
    }
}
