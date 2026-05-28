

import SwiftUI

struct SDKSystemExplorerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var runtime = SDKRuntimeEngine.shared

    var body: some View {
        List {
            Section {
                Toggle("Developer Mode", isOn: $runtime.isNoSandboxModeEnabled)
                    .tint(.red)
            } header: {
                Text("Kernel Control")
            } footer: {
                if runtime.isNoSandboxModeEnabled {
                    Label("All scope restrictions currently bypassed", systemImage: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("Enable to bypass all security boundaries for local testing.")
                }
            }

            Section(header: Text("Interface Explorer")) {
                ExplorerLink(title: "Notes API", module: "Notes", icon: "note.text")
                ExplorerLink(title: "Tasks API", module: "checkmark.circle", icon: "checkmark.circle")
                ExplorerLink(title: "Mail API", module: "Mail", icon: "envelope")
                ExplorerLink(title: "Calendar API", module: "Calendar", icon: "calendar")
                ExplorerLink(title: "Files API", module: "Files", icon: "doc")
                ExplorerLink(title: "Slides API", module: "Slides", icon: "rectangle.on.rectangle")
                ExplorerLink(title: "Meet API", module: "Meet", icon: "video")
                ExplorerLink(title: "Persona API", module: "Persona", icon: "brain")
            }

            Section(header: Text("Deep Data Access")) {
                NavigationLink { EntityExplorerView() } label: { Label("Active Entities", systemImage: "cylinder.fill") }
                NavigationLink { SDKWorkspaceExplorerView() } label: { Label("Workspace Graph", systemImage: "circle.grid.cross") }
                NavigationLink { SDKEventStreamView() } label: { Label("Event Stream", systemImage: "bolt.fill") }
            }

            Section(header: Text("SDK Internals")) {
                let metrics = SDKTelemetryEngine.shared.getMetrics()
                LabeledContent("Total Traces", value: "\(metrics.totalTraces)")
                LabeledContent("Active Sync Channels", value: "\(SDKRealtimeSync.shared.activeChannels.count)")
                LabeledContent("Plugins Loaded", value: "\(SDKPluginManager.shared.plugins.count)")
                LabeledContent("Connectors Registered", value: "\(SDKConnectorManager.shared.connectors.count)")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("System Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

// MARK: - Private Subviews

private struct ExplorerLink: View {
    let title: String, module: String, icon: String
    var body: some View {
        NavigationLink { APIExplorerDetail(module: module) } label: { Label(title, systemImage: icon) }
    }
}

struct APIExplorerDetail: View {
    let module: String
    var body: some View {
        List {
            Section(header: Text("Exposed Methods")) {
                ForEach(methods, id: \.self) { Text($0).font(.caption.monospaced()) }
            }
            Section(header: Text("Live Stats")) {
                LabeledContent("Object Count") {
                    Text("\(count)").monospaced().bold().foregroundStyle(Color.accentColor)
                }
            }
        }
        .navigationTitle("\(module) Explorer")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var methods: [String] {
        switch module {
        case "Notes": return ["\(module).list()", "\(module).create(title, content)"]
        case "Tasks": return ["\(module).list()", "\(module).create(title, dueDate)"]
        default: return ["\(module).list()"]
        }
    }

    private var count: Int {
        switch module {
        case "Notes": return WorkspaceAPI.shared.notes.listNotes().count
        case "Tasks": return WorkspaceAPI.shared.tasks.listTasks().count
        default: return 0
        }
    }
}

struct EntityExplorerView: View {
    var body: some View {
        List {
            Section(header: Text("Notes")) {
                ForEach(WorkspaceAPI.shared.notes.listNotes()) { note in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.title).font(.subheadline.bold())
                        Text(note.content.prefix(50)).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Section(header: Text("Tasks")) {
                ForEach(WorkspaceAPI.shared.tasks.listTasks()) { task in
                    Label(task.title, systemImage: task.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.completed ? Color.green : Color.secondary)
                }
            }
            Section(header: Text("Snapshots")) {
                ForEach(WorkspaceAPI.shared.timeTravel.listSnapshots()) { snap in
                    LabeledContent(snap.message, value: snap.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Live Entities")
        .navigationBarTitleDisplayMode(.inline)
    }
}
