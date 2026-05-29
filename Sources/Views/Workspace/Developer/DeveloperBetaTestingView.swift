import SwiftUI

struct DeveloperBetaTestingView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Select an App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Beta Groups") {
                if selectedAppID != nil {
                    Text("No beta groups configured. Create a group to start testing your app.").font(.caption).foregroundStyle(.secondary)

                    Button("Create Beta Group") {
                        // Awaiting backend integration
                    }
                } else {
                    Text("Select an app to manage beta testing.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Beta Testing")
    }
}
