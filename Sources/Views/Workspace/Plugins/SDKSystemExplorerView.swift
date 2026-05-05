import SwiftUI

struct SDKSystemExplorerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var runtime = SDKRuntimeEngine.shared

    var body: some View {
        List {
            Section {
                Toggle("Try with SDK", isOn: $runtime.isNoSandboxModeEnabled)
                    .tint(.red)
            }

            Section("Workspace API Graph") {
                NavigationLink("Notes API", destination: APIExplorerDetail(module: "Notes"))
                NavigationLink("Tasks API", destination: APIExplorerDetail(module: "Tasks"))
                NavigationLink("Mail API", destination: APIExplorerDetail(module: "Mail"))
                NavigationLink("Calendar API", destination: APIExplorerDetail(module: "Calendar"))
                NavigationLink("Files API", destination: APIExplorerDetail(module: "Files"))
                NavigationLink("Meet API", destination: APIExplorerDetail(module: "Meet"))
            }

            Section("Live System Data") {
                NavigationLink("Active Entities", destination: EntityExplorerView())
                NavigationLink("Runtime Dependencies", destination: Text("Dependency Graph Content"))
            }
        }
        .navigationTitle("System Explorer")
        .toolbar {
            Button("Done") { dismiss() }
        }
    }
}

struct APIExplorerDetail: View {
    let module: String
    var body: some View {
        List {
            Section("Methods") {
                Text("\(module).list()").font(.system(.body, design: .monospaced))
                Text("\(module).create(params)").font(.system(.body, design: .monospaced))
                Text("\(module).delete(id)").font(.system(.body, design: .monospaced))
            }
        }
        .navigationTitle("\(module) Explorer")
    }
}

struct EntityExplorerView: View {
    var body: some View {
        List {
            Section("Notes") {
                ForEach(WorkspaceAPI.shared.notes.listNotes()) { note in
                    Text(note.title)
                }
            }

            Section("Files") {
                ForEach(WorkspaceAPI.shared.files.listFiles()) { file in
                    Label(file.name, systemImage: "doc")
                }
            }

            Section("System Snapshots (Time Travel)") {
                ForEach(WorkspaceAPI.shared.timeTravel.listSnapshots()) { snapshot in
                    VStack(alignment: .leading) {
                        Text(snapshot.message).font(.subheadline)
                        Text(snapshot.timestamp.formatted()).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Live Entities")
    }
}
