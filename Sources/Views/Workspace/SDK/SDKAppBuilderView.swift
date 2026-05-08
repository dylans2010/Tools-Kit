import SwiftUI

struct SDKAppBuilderView: View {
    @ObservedObject var runtime = PluginRuntimeEngine.shared
    @State private var newAppName = ""
    @State private var newAppDescription = ""

    var body: some View {
        List {
            Section {
                TextField("App Name", text: $newAppName)
                TextField("Description", text: $newAppDescription)
                Button("Create SDK App") {
                    let def = SDKAppDefinition(name: newAppName, description: newAppDescription)
                    try? runtime.register(def)
                    newAppName = ""
                    newAppDescription = ""
                }
                .disabled(newAppName.isEmpty)
            } header: {
                Text("Create New App")
            }

            Section {
                if runtime.loadedApps.isEmpty {
                    Text("No apps registered.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(runtime.loadedApps) { app in
                        VStack(alignment: .leading) {
                            Text(app.name).font(.headline)
                            Text(app.description).font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Text("Version: \(app.version)")
                                Spacer()
                                if runtime.isRunning(app.id) {
                                    StatusBadge(status: "Running", color: .green)
                                }
                            }
                            .font(.caption2)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            runtime.unregister(appId: runtime.loadedApps[index].id)
                        }
                    }
                }
            } header: {
                Text("Registered Apps")
            }
        }
        .navigationTitle("App Builder")
    }
}
