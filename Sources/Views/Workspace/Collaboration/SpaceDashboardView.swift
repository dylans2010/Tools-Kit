import SwiftUI

struct SpaceDashboardView: View {
    let spaceID: UUID
    @StateObject private var manager = CollaborationManager.shared
    @State private var selectedTab = 0
    @State private var showingAddData = false

    private var space: CollaborationSpace? {
        manager.spaces.first { $0.id == spaceID }
    }

    var body: some View {
        Group {
            if let space = space {
                VStack(spacing: 0) {
                    Picker("Tab", selection: $selectedTab) {
                        Image(systemName: "house").tag(0)
                        Image(systemName: "book").tag(1)
                        Image(systemName: "rectangle.on.rectangle.angled").tag(2)
                        Image(systemName: "video").tag(3)
                        Image(systemName: "list.bullet.rectangle").tag(4)
                        Image(systemName: "tablecells").tag(5)
                        Image(systemName: "photo.on.rectangle").tag(6)
                        Image(systemName: "clock").tag(7)
                        Image(systemName: "gear").tag(8)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    contentView(for: space)
                }
                .navigationTitle(space.name)
                .toolbar {
                    Button(action: { showingAddData = true }) {
                        Image(systemName: "plus.circle")
                    }
                }
                .sheet(isPresented: $showingAddData) {
                    AddDataCollabView(spaceID: space.id)
                }
            } else {
                Text("Space not found.")
            }
        }
    }

    @ViewBuilder
    private func contentView(for space: CollaborationSpace) -> some View {
        switch selectedTab {
        case 0: SpaceOverviewTab(space: space)
        case 1: SpaceObjectsList(title: "Notebooks", ids: space.notebookIDs, icon: "book")
        case 2: SpaceObjectsList(title: "Slides", ids: space.slideDeckIDs, icon: "rectangle.on.rectangle.angled")
        case 3: ProjectBoardView(spaceID: space.id)
        case 4: DecisionEngineView(spaceID: space.id)
        case 5: SpaceObjectsList(title: "Sheets", ids: space.spreadsheetIDs, icon: "tablecells")
        case 6: SpaceObjectsList(title: "Media Projects", ids: space.mediaProjectIDs, icon: "photo.on.rectangle")
        case 7: VersionHistoryView(spaceID: space.id)
        case 8: Text("Settings Content")
        default: EmptyView()
        }
    }
}

struct SpaceOverviewTab: View {
    let space: CollaborationSpace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if space.description.isEmpty {
                    Text("No description provided.")
                        .italic()
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    Text(space.description)
                        .padding(.horizontal)
                }

                Divider()

                Text("Activity Feed")
                    .font(.headline)
                    .padding(.horizontal)

                if space.activityFeed.isEmpty {
                    Text("No activity yet.")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    ForEach(space.activityFeed) { log in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(log.action)
                                    .font(.subheadline)
                                Text("\(log.userName) • \(log.timestamp, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct SpaceObjectsList: View {
    let title: String
    let ids: [UUID]
    let icon: String

    var body: some View {
        List {
            if ids.isEmpty {
                Text("No \(title.lowercased()) added to this space.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(ids, id: \.self) { id in
                    objectRow(id: id)
                }
            }
        }
    }

    @ViewBuilder
    private func objectRow(id: UUID) -> some View {
        if let type = CollaborationFramework.shared.indexedObjects[id] {
            switch type {
            case .notebook:
                if let notebook = NotebooksManager.shared.notebooks.first(where: { $0.id == id }) {
                    NavigationLink(destination: NotebookDetailView(notebook: notebook)) {
                        Label(notebook.name, systemImage: "book")
                    }
                } else {
                    Label("Notebook \(id.uuidString.prefix(4))", systemImage: "book")
                }
            case .slideDeck:
                if let deck = SlideDecksManager.shared.slideDecks.first(where: { $0.id == id }) {
                    NavigationLink(destination: SlideEditorView(deckID: deck.id)) {
                        Label(deck.title, systemImage: "rectangle.on.rectangle.angled")
                    }
                } else {
                    Label("Slide Deck \(id.uuidString.prefix(4))", systemImage: "rectangle.on.rectangle.angled")
                }
            case .spreadsheet:
                if let sheet = SpreadsheetsManager.shared.spreadsheets.first(where: { $0.id == id }) {
                    NavigationLink(destination: SpreadsheetEditorView(spreadsheetID: sheet.id)) {
                        Label(sheet.name, systemImage: "tablecells")
                    }
                } else {
                    Label("Spreadsheet \(id.uuidString.prefix(4))", systemImage: "tablecells")
                }
            case .mediaProject:
                if let project = EditingManager.shared.projects.first(where: { $0.id == id }) {
                    NavigationLink(destination: FullEditorView(projectID: project.id)) {
                        Label(project.name, systemImage: "photo.on.rectangle")
                    }
                } else {
                    Label("Media Project \(id.uuidString.prefix(4))", systemImage: "photo.on.rectangle")
                }
            default:
                Label("\(type.rawValue.capitalized) \(id.uuidString.prefix(4))", systemImage: icon)
            }
        } else {
            Label("Object \(id.uuidString.prefix(8))", systemImage: icon)
        }
    }
}
