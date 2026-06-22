import SwiftUI

struct AFMMainView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: AFMDashboardView()) {
                    Label("Dashboard", systemImage: "sparkles")
                }
                NavigationLink(destination: AFMTaskView()) {
                    Label("Tasks", systemImage: "list.bullet.clipboard")
                }
            } header: {
                Text("Overview")
            }

            Section {
                NavigationLink(destination: AFMSettingsView()) {
                    Label("Settings", systemImage: "gearshape")
                }
            } header: {
                Text("Preferences")
            }
        }
        .navigationTitle("AFM")
    }
}
