import SwiftUI

struct SDKAppRuntimeView: View {
    @StateObject private var runtime = SDKAppRuntime.shared

    var body: some View {
        List {
            Section("Active Apps") {
                if runtime.activeApps.isEmpty {
                    Text("No apps running").foregroundStyle(.secondary)
                } else {
                    ForEach(Array(runtime.activeApps.values), id: \.id) { instance in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(instance.manifest.name).font(.headline)
                                Text("v\(instance.manifest.version)").font(.caption)
                            }
                            Spacer()
                            Button("Stop") {
                                runtime.terminateApp(id: instance.id)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("App Runtime")
    }
}
