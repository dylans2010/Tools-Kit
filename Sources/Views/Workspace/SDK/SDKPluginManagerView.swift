import SwiftUI

struct SDKPluginManagerView: View {
    @ObservedObject var runtime = PluginRuntimeEngine.shared
    @State private var showingAddPlugin = false

    var body: some View {
        List {
            Section {
                ForEach(runtime.loadedApps) { app in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(app.name).font(.subheadline.bold())
                            Text(app.id.uuidString).font(.system(.caption2, design: .monospaced)).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { runtime.isRunning(app.id) },
                            set: { newValue in
                                Task {
                                    if newValue {
                                        try? await runtime.start(appId: app.id)
                                    } else {
                                        try? await runtime.stop(appId: app.id)
                                    }
                                }
                            }
                        ))
                    }
                }
            } header: {
                Text("Installed Plugins & Apps")
            }

            Section {
                NavigationLink(destination: SDKPermissionControlView()) {
                    Label("Configure Permissions", systemImage: "shield.lefthalf.filled")
                }
            } header: {
                Text("Security")
            }
        }
        .navigationTitle("Plugin Manager")
    }
}
