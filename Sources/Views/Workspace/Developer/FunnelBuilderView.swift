import SwiftUI

struct FunnelBuilderView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Select App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Conversion Funnels") {
                if selectedAppID == nil {
                    Text("Select an app to manage funnels.").foregroundStyle(.secondary)
                } else {
                    Text("No funnels defined for this app.").foregroundStyle(.secondary)

                    Button("Create New Funnel") {
                        // Add logic
                    }
                }
            }
        }
        .navigationTitle("Funnel Builder")
    }
}
