import SwiftUI

struct SpaceDashboardView: View {
    let spaceID: UUID
    @StateObject private var manager = SpaceCollabManager.shared
    @State private var selectedTab = SpaceTab.overview
    @State private var showingAddData = false

    enum SpaceTab: String, CaseIterable {
        case overview = "Overview"
        case messages = "Messages"
        case files = "Files"
        case notebooks = "Notebooks"
        case slides = "Slides"
        case meetings = "Meetings"
        case decisions = "Decisions"
        case sheets = "Sheets"
        case media = "Media"
        case prs = "Pull Requests"
        case history = "History"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .overview: return "house"
            case .messages: return "bubble.left.and.bubble.right"
            case .files: return "doc"
            case .notebooks: return "book"
            case .slides: return "rectangle.on.rectangle.angled"
            case .meetings: return "video"
            case .decisions: return "list.bullet.rectangle"
            case .sheets: return "tablecells"
            case .media: return "photo.on.rectangle"
            case .prs: return "arrow.triangle.pull"
            case .history: return "clock"
            case .settings: return "gear"
            }
        }
    }

    private var space: CollaborationSpace? {
        manager.spaces.first { $0.id == spaceID }
    }

    var body: some View {
        Group {
            if let space = space {
                VStack(spacing: 0) {
                    HStack {
                        Menu {
                            ForEach(SpaceTab.allCases, id: \.self) { tab in
                                Button(action: { selectedTab = tab }) {
                                    Label(tab.rawValue, systemImage: tab.icon)
                                }
                            }
                        } label: {
                            HStack {
                                Label(selectedTab.rawValue, systemImage: selectedTab.icon)
                                    .font(.headline)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        Spacer()
                    }
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
                Text("Space Not Found")
            }
        }
    }

    @ViewBuilder
    private func contentView(for space: CollaborationSpace) -> some View {
        switch selectedTab {
        case .overview: SpaceOverviewTab(space: space)
        case .messages: SpaceMessagesTab(spaceID: space.id)
        case .files: SpaceFilesTab(spaceID: space.id)
        case .notebooks: SpaceObjectsList(title: "Notebooks", ids: space.notebookIDs, icon: "book")
        case .slides: SpaceObjectsList(title: "Slides", ids: space.slideDeckIDs, icon: "rectangle.on.rectangle.angled")
        case .meetings: ProjectBoardView(spaceID: space.id)
        case .decisions: DecisionEngineView(spaceID: space.id)
        case .sheets: SpaceObjectsList(title: "Sheets", ids: space.spreadsheetIDs, icon: "tablecells")
        case .media: SpaceObjectsList(title: "Media Projects", ids: space.mediaProjectIDs, icon: "photo.on.rectangle")
        case .prs: PullRequestDashboardView(spaceID: space.id)
        case .history: SpaceVersionHistoryView(spaceID: space.id)
        case .settings: SpaceSettingsTab(spaceID: space.id)
        }
    }
}

struct SpaceMessagesTab: View {
    let spaceID: UUID
    @StateObject private var manager = SpaceCollabManager.shared
    @State private var newMessage = ""

    private var space: CollaborationSpace? {
        manager.spaces.first { $0.id == spaceID }
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if let messages = space?.messages {
                            ForEach(messages) { message in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(message.senderName)
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                    Text(message.content)
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(12)
                                    Text(message.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: space?.messages.count) { _, _ in
                    if let lastID = space?.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastID) }
                    }
                }
            }

            HStack {
                TextField("Message", text: $newMessage)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    if !newMessage.isEmpty {
                        manager.sendMessage(spaceID: spaceID, content: newMessage)
                        newMessage = ""
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct SpaceFilesTab: View {
    let spaceID: UUID
    @StateObject private var manager = SpaceCollabManager.shared

    private var space: CollaborationSpace? {
        manager.spaces.first { $0.id == spaceID }
    }

    var body: some View {
        List {
            if let files = space?.sharedFiles, !files.isEmpty {
                ForEach(files) { file in
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(file.name)
                                .font(.subheadline.bold())
                            Text("\(file.size / 1024) KB • \(file.timestamp, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("No files shared yet.")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SpaceSettingsTab: View {
    let spaceID: UUID
    @StateObject private var manager = SpaceCollabManager.shared
    @State private var showingAddMember = false

    private var space: CollaborationSpace? {
        manager.spaces.first { $0.id == spaceID }
    }

    var body: some View {
        List {
            Section {
                if let space = space {
                    ForEach(space.members) { member in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(member.name)
                                    .font(.subheadline.bold())
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(member.role.rawValue)
                                .font(.caption2)
                                .padding(4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                Button("Add Member") {
                    showingAddMember = true
                }
            } header: {
                Text("Members")
            }
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
                    Text("No Activity Yet")
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
                    Label("Object \(id.uuidString.prefix(8))", systemImage: icon)
                }
            }
        }
    }
}
