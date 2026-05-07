import SwiftUI

struct SDKProjectDashboardView: View {
    @StateObject private var sdk = WorkspaceSDK.shared
    @StateObject private var kernel = WorkspaceSDKKernel.shared

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("System Status")) {
                    HStack {
                        Text("Kernel Status")
                        Spacer()
                        Text(kernel.isInitialized ? "Initialized" : "Pending")
                            .foregroundColor(kernel.isInitialized ? .green : .orange)
                    }
                    HStack {
                        Text("Environment")
                        Spacer()
                        Text("\(sdk.environment.mode == .development ? "Development" : "Production")")
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("Feature Modules")) {
                    NavigationLink("Mail Service", destination: Text("Mail Module Controls"))
                    NavigationLink("Notebooks Service", destination: Text("Notebooks Module Controls"))
                    NavigationLink("Meet Service", destination: Text("Meet Module Controls"))
                    NavigationLink("Articles Service", destination: Text("Articles Module Controls"))
                }

                Section(header: Text("Core Services")) {
                    NavigationLink("Data Store", destination: SDKDataControlView())
                    NavigationLink("Internal Router", destination: SDKAPIBrowserView())
                    NavigationLink("Event Bus", destination: SDKEventStreamView())
                    NavigationLink("Permission Manager", destination: SDKPermissionControlView())
                }

                Section(header: Text("Development Tools")) {
                    NavigationLink("App Builder", destination: SDKAppBuilderView())
                    NavigationLink("Plugin Manager", destination: SDKPluginsView())
                    NavigationLink("Developer Guide", destination: SDKDeveloperGuideView())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("WorkspaceSDK")
            .toolbar {
                Button(kernel.isInitialized ? "Shutdown" : "Bootstrap") {
                    Task {
                        if kernel.isInitialized {
                            await kernel.shutdown()
                        } else {
                            await kernel.bootstrap()
                        }
                    }
                }
            }
        }
    }
}
