import SwiftUI

struct AFMMainView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AFMDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "sparkles")
                }
                .tag(0)

            AFMTaskView()
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet.clipboard")
                }
                .tag(1)

            AFMSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .navigationTitle("Apple Foundation Models")
        .navigationBarTitleDisplayMode(.inline)
    }
}
