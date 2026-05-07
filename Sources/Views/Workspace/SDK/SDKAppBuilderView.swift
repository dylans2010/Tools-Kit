import SwiftUI

struct SDKAppBuilderView: View {
    @StateObject private var runtime = PluginRuntime.shared
    @State private var showingCreateSheet = false

    var body: some View {
        List {
            Section(header: Text("Active Apps")) {
                if runtime.activeApps.isEmpty {
                    Text("No active apps").foregroundColor(.secondary)
                } else {
                    ForEach(runtime.activeApps, id: \.id) { app in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(app.name).font(.headline)
                                Text("v\(app.version) by \(app.author)").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Stop") {
                                Task {
                                    await runtime.stopApp(id: app.id)
                                }
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }

            Section(header: Text("Loaded Plugins")) {
                if runtime.loadedPlugins.isEmpty {
                    Text("No plugins loaded").foregroundColor(.secondary)
                } else {
                    ForEach(runtime.loadedPlugins, id: \.id) { plugin in
                        VStack(alignment: .leading) {
                            Text(plugin.name).font(.headline)
                            Text(plugin.identifier).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("App Builder")
        .toolbar {
            Button(action: { showingCreateSheet = true }) {
                Image(systemName: "plus")
            }
        }
    }
}
