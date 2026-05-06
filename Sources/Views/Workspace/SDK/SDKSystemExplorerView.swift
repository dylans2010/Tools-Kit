import SwiftUI

struct SDKSystemExplorerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var runtime = SDKRuntimeEngine.shared

    var body: some View {
        List {
            Section {
                Toggle("Try with SDK", isOn: $runtime.isNoSandboxModeEnabled)
                    .tint(.red)

                if runtime.isNoSandboxModeEnabled {
                    Label("All scope restrictions bypassed", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("Workspace API Graph") {
                NavigationLink("Notes API", destination: APIExplorerDetail(module: "Notes"))
                NavigationLink("Tasks API", destination: APIExplorerDetail(module: "Tasks"))
                NavigationLink("Mail API", destination: APIExplorerDetail(module: "Mail"))
                NavigationLink("Calendar API", destination: APIExplorerDetail(module: "Calendar"))
                NavigationLink("Files API", destination: APIExplorerDetail(module: "Files"))
                NavigationLink("Slides API", destination: APIExplorerDetail(module: "Slides"))
                NavigationLink("Meet API", destination: APIExplorerDetail(module: "Meet"))
                NavigationLink("Persona API", destination: APIExplorerDetail(module: "Persona"))
            }

            Section("Live System Data") {
                NavigationLink("Active Entities", destination: EntityExplorerView())
                NavigationLink("Workspace Graph", destination: SDKWorkspaceExplorerView())
                NavigationLink("Event Stream", destination: SDKEventStreamView())
            }

            Section("SDK Internals") {
                let metrics = SDKTelemetryEngine.shared.getMetrics()
                HStack {
                    Text("Total Traces")
                    Spacer()
                    Text("\(metrics.totalTraces)").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Active Channels")
                    Spacer()
                    Text("\(SDKRealtimeSync.shared.activeChannels.count)").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Plugins Loaded")
                    Spacer()
                    Text("\(SDKPluginManager.shared.plugins.count)").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Connectors")
                    Spacer()
                    Text("\(SDKConnectorManager.shared.connectors.count)").font(.caption).foregroundStyle(.secondary)
                }
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
                ForEach(methodsForModule, id: \.self) { method in
                    Text(method).font(.system(.body, design: .monospaced))
                }
            }

            Section("Live Data Count") {
                HStack {
                    Text("Items")
                    Spacer()
                    Text("\(liveCount)").font(.system(.body, design: .monospaced)).foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle("\(module) Explorer")
    }

    private var methodsForModule: [String] {
        switch module {
        case "Notes": return ["\(module).list()", "\(module).create(title, content)"]
        case "Tasks": return ["\(module).list()", "\(module).create(title, dueDate)"]
        case "Mail": return ["\(module).list()", "\(module).send(to, subject, body)"]
        case "Calendar": return ["\(module).list()", "\(module).create(title, start, end)"]
        case "Files": return ["\(module).list()", "\(module).delete(id)"]
        case "Slides": return ["\(module).list()", "\(module).create(title)", "\(module).generateContent(deckID, prompt)"]
        case "Meet": return ["\(module).start(title)"]
        case "Persona": return ["\(module).query(prompt)", "\(module).injectMemory(entityID, content)", "\(module).getInsights()"]
        default: return ["\(module).list()"]
        }
    }

    private var liveCount: Int {
        switch module {
        case "Notes": return WorkspaceAPI.shared.notes.listNotes().count
        case "Tasks": return WorkspaceAPI.shared.tasks.listTasks().count
        case "Mail": return WorkspaceAPI.shared.mail.listMessages().count
        case "Calendar": return WorkspaceAPI.shared.calendar.listEvents().count
        case "Files": return WorkspaceAPI.shared.files.listFiles().count
        case "Slides": return WorkspaceAPI.shared.slides.listDecks().count
        case "Persona": return WorkspaceAPI.shared.persona.getInsights().count
        default: return 0
        }
    }
}

struct EntityExplorerView: View {
    var body: some View {
        List {
            Section("Notes (\(WorkspaceAPI.shared.notes.listNotes().count))") {
                ForEach(WorkspaceAPI.shared.notes.listNotes()) { note in
                    VStack(alignment: .leading) {
                        Text(note.title).font(.subheadline)
                        Text(note.content.prefix(50)).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Tasks (\(WorkspaceAPI.shared.tasks.listTasks().count))") {
                ForEach(WorkspaceAPI.shared.tasks.listTasks()) { task in
                    HStack {
                        Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.completed ? .green : .secondary)
                        Text(task.title).font(.subheadline)
                    }
                }
            }

            Section("Files (\(WorkspaceAPI.shared.files.listFiles().count))") {
                ForEach(WorkspaceAPI.shared.files.listFiles(), id: \.id) { file in
                    Label(file.name, systemImage: "doc")
                }
            }

            Section("Slide Decks (\(WorkspaceAPI.shared.slides.listDecks().count))") {
                ForEach(WorkspaceAPI.shared.slides.listDecks()) { deck in
                    Text(deck.title).font(.subheadline)
                }
            }

            Section("System Snapshots (\(WorkspaceAPI.shared.timeTravel.listSnapshots().count))") {
                ForEach(WorkspaceAPI.shared.timeTravel.listSnapshots()) { snapshot in
                    VStack(alignment: .leading) {
                        Text(snapshot.message).font(.subheadline)
                        Text(snapshot.timestamp.formatted()).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Live Entities")
        .refreshable {}
    }
}
