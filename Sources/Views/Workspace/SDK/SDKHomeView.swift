import SwiftUI

struct SDKHomeView: View {
    @ObservedObject var sdk = WorkspaceSDK.shared

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Kernel Status")
                        Spacer()
                        StatusBadge(status: sdk.kernel.state.rawValue, color: sdk.kernel.isReady ? .green : .orange)
                    }

                    HStack {
                        Text("SDK Version")
                        Spacer()
                        Text(sdk.version).foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Active Services")
                        Spacer()
                        Text("\(sdk.kernel.healthCheck().registeredServices)").foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("System Health")
            }

            Section {
                NavigationLink(destination: SDKDeveloperGuideView()) {
                    Label("Developer Guide", systemImage: "book.fill")
                }
                NavigationLink(destination: SDKAppBuilderView()) {
                    Label("App Builder", systemImage: "hammer.fill")
                }
                NavigationLink(destination: SDKAPIBrowserView()) {
                    Label("API Browser", systemImage: "network")
                }
                NavigationLink(destination: SDKDataControlView()) {
                    Label("Data Control", systemImage: "database")
                }
                NavigationLink(destination: SDKPluginManagerView()) {
                    Label("Plugin Manager", systemImage: "puzzlepiece.fill")
                }
            } header: {
                Text("Developer Tools")
            }
        }
        .navigationTitle("WorkspaceSDK")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Boot") {
                    Task { await sdk.initialize() }
                }
            }
        }
    }
}

struct StatusBadge: View {
    let status: String
    let color: Color

    var body: some View {
        Text(status.uppercased())
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}
