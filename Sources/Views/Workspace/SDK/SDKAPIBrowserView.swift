import SwiftUI

struct SDKAPIBrowserView: View {
    @State private var searchText = ""
    @State private var selectedCategory: APICategory = .all

    enum APICategory: String, CaseIterable {
        case all = "All"
        case workspace = "Workspace"
        case sdk = "SDK"
        case tools = "Tools"
        case connectors = "Connectors"
    }

    var body: some View {
        List {
            Section("Available Methods (\(filteredMethods.count))") {
                ForEach(filteredMethods, id: \.name) { method in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(method.name)
                            .font(.system(.subheadline, design: .monospaced))
                            .bold()
                        Text(method.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text(method.category.rawValue)
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                            if method.isAsync {
                                Text("async")
                                    .font(.system(size: 9, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("API Browser")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(APICategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var filteredMethods: [APIMethod] {
        var result = allMethods
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private var allMethods: [APIMethod] {
        var methods: [APIMethod] = [
            APIMethod(name: "workspace.notes.list()", description: "List all notes from NotebooksManager", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.notes.create(title, content)", description: "Create a note via NotebooksManager", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.tasks.list()", description: "List all tasks from TasksManager", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.tasks.create(title, dueDate)", description: "Create a task via TasksManager", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.mail.list()", description: "List mail messages from MailStorageService", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.mail.send(to, subject, body)", description: "Send mail via MailSMTPService", category: .workspace, isAsync: true),
            APIMethod(name: "workspace.calendar.list()", description: "List calendar events from CalendarManager", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.calendar.create(title, start, end)", description: "Create calendar event", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.files.list()", description: "List workspace files", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.files.delete(id)", description: "Delete a workspace file", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.slides.list()", description: "List slide decks from SlideDecksManager", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.slides.create(title)", description: "Create a slide deck", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.meet.start(title)", description: "Start a meeting via DailyService", category: .workspace, isAsync: true),
            APIMethod(name: "workspace.persona.query(prompt)", description: "Query AI persona via PersonaManager", category: .workspace, isAsync: true),
            APIMethod(name: "workspace.persona.injectMemory(entityID, content)", description: "Inject memory into AI persona", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.timeTravel.listSnapshots()", description: "List time-travel snapshots", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.timeTravel.restore(snapshotID)", description: "Restore workspace state from snapshot", category: .workspace, isAsync: false),
            APIMethod(name: "workspace.timeTravel.createSnapshot(message)", description: "Create workspace snapshot", category: .workspace, isAsync: false),
            APIMethod(name: "sdk.fetchData(scope, query)", description: "Fetch workspace data via SDK data engine", category: .sdk, isAsync: true),
            APIMethod(name: "sdk.writeData(scope, data)", description: "Write data through SDK pipeline", category: .sdk, isAsync: true),
            APIMethod(name: "sdk.deleteData(scope, ids)", description: "Delete workspace data items", category: .sdk, isAsync: true),
            APIMethod(name: "sdk.batchUpdate(operations)", description: "Execute batch data operations", category: .sdk, isAsync: true),
            APIMethod(name: "sdk.execute(action, context)", description: "Execute SDK action via kernel", category: .sdk, isAsync: true),
            APIMethod(name: "sdk.events.emit(type, payload)", description: "Emit SDK event", category: .sdk, isAsync: false),
            APIMethod(name: "sdk.events.subscribe(handler)", description: "Subscribe to SDK events", category: .sdk, isAsync: false),
            APIMethod(name: "sdk.realtime.subscribe(channel)", description: "Subscribe to realtime channel", category: .sdk, isAsync: false),
            APIMethod(name: "sdk.realtime.broadcast(channel, data)", description: "Broadcast to realtime channel", category: .sdk, isAsync: false),
            APIMethod(name: "sdk.graph.query(entityType, relation)", description: "Query the workspace knowledge graph", category: .sdk, isAsync: false),
            APIMethod(name: "sdk.graph.link(source, target, relation)", description: "Link entities in the graph", category: .sdk, isAsync: false),
            APIMethod(name: "sdk.audit.log(message, source, level)", description: "Write to audit log", category: .sdk, isAsync: false),
            APIMethod(name: "sdk.developer.noSandbox", description: "Toggle unrestricted execution mode", category: .sdk, isAsync: false),
        ]

        let tools = SDKToolManager.shared.tools
        for tool in tools {
            let params = tool.inputSchema.map { $0.key }.joined(separator: ", ")
            methods.append(APIMethod(name: "sdk.tools.\(tool.name.lowercased().replacingOccurrences(of: " ", with: "_"))(\(params))", description: "Execute Tool: \(tool.name)", category: .tools, isAsync: true))
        }

        let connectors = SDKConnectorManager.shared.connectors
        for connector in connectors {
            methods.append(APIMethod(name: "sdk.connectors.\(connector.name.lowercased()).sync()", description: "Sync \(connector.name) Connector", category: .connectors, isAsync: true))
        }

        return methods
    }
}

struct APIMethod: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: SDKAPIBrowserView.APICategory
    let isAsync: Bool
}
