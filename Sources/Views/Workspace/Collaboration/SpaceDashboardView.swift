import SwiftUI

// MARK: - Space Template

struct SpaceTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: Color
    let tabs: [SpaceDashboardView.SpaceTab]
    let suggestedVisibility: SpaceVisibility

    static let allTemplates: [SpaceTemplate] = [
        SpaceTemplate(
            name: "Product Launch",
            description: "Plan and execute a product launch with tasks, timelines, and media assets",
            icon: "rocket.fill",
            color: .orange,
            tabs: [.overview, .files, .meetings, .decisions, .media, .history],
            suggestedVisibility: .shared
        ),
        SpaceTemplate(
            name: "Creative Studio",
            description: "Collaborative creative workspace for design, media, and content production",
            icon: "paintbrush.fill",
            color: .purple,
            tabs: [.overview, .media, .files, .notebooks, .slides, .messages],
            suggestedVisibility: .shared
        ),
        SpaceTemplate(
            name: "Engineering Sprint",
            description: "Sprint planning with pull requests, code reviews, and issue tracking",
            icon: "hammer.fill",
            color: .blue,
            tabs: [.overview, .prs, .meetings, .decisions, .history, .settings],
            suggestedVisibility: .privateSpace
        ),
        SpaceTemplate(
            name: "Research Hub",
            description: "Organize research notes, data sheets, and collaborative analysis",
            icon: "magnifyingglass",
            color: .green,
            tabs: [.overview, .notebooks, .sheets, .files, .decisions, .history],
            suggestedVisibility: .privateSpace
        ),
        SpaceTemplate(
            name: "Client Project",
            description: "External collaboration with clients including presentations and deliverables",
            icon: "person.2.fill",
            color: .cyan,
            tabs: [.overview, .slides, .files, .meetings, .messages, .history],
            suggestedVisibility: .shared
        ),
        SpaceTemplate(
            name: "Content Calendar",
            description: "Plan and schedule content across channels with team coordination",
            icon: "calendar.badge.clock",
            color: .pink,
            tabs: [.overview, .media, .slides, .sheets, .messages, .settings],
            suggestedVisibility: .shared
        ),
        SpaceTemplate(
            name: "Blank Space",
            description: "Start from scratch with a completely empty workspace",
            icon: "square.dashed",
            color: .secondary,
            tabs: SpaceDashboardView.SpaceTab.allCases,
            suggestedVisibility: .privateSpace
        ),
    ]
}

// MARK: - SpaceDashboardView

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
            case .overview: return "house.fill"
            case .messages: return "bubble.left.and.bubble.right.fill"
            case .files: return "doc.fill"
            case .notebooks: return "book.fill"
            case .slides: return "rectangle.on.rectangle.angled"
            case .meetings: return "video.fill"
            case .decisions: return "list.bullet.rectangle.fill"
            case .sheets: return "tablecells.fill"
            case .media: return "photo.on.rectangle.angled"
            case .prs: return "arrow.triangle.pull"
            case .history: return "clock.fill"
            case .settings: return "gearshape.fill"
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
                    tabSelector
                    Divider()
                    contentView(for: space)
                }
                .navigationTitle(space.name)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        if !space.activeUsers.isEmpty {
                            HStack(spacing: -4) {
                                ForEach(space.activeUsers.prefix(3), id: \.self) { _ in
                                    Image(systemName: "person.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        Button(action: { showingAddData = true }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
                .sheet(isPresented: $showingAddData) {
                    AddDataCollabView(spaceID: space.id)
                }
            } else {
                ContentUnavailableView(
                    "Space Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This space may have been deleted or you may not have access.")
                )
            }
        }
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(SpaceTab.allCases, id: \.self) { tab in
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func contentView(for space: CollaborationSpace) -> some View {
        switch selectedTab {
        case .overview: SpaceOverviewTab(space: space)
        case .messages: SpaceMessagesTab(spaceID: space.id)
        case .files: SpaceFilesTab(spaceID: space.id)
        case .notebooks: SpaceObjectsList(title: "Notebooks", ids: space.notebookIDs, icon: "book.fill")
        case .slides: SpaceObjectsList(title: "Slides", ids: space.slideDeckIDs, icon: "rectangle.on.rectangle.angled")
        case .meetings: ProjectBoardView(spaceID: space.id)
        case .decisions: DecisionEngineView(spaceID: space.id)
        case .sheets: SpaceObjectsList(title: "Sheets", ids: space.spreadsheetIDs, icon: "tablecells.fill")
        case .media: SpaceObjectsList(title: "Media Projects", ids: space.mediaProjectIDs, icon: "photo.on.rectangle.angled")
        case .prs: PullRequestDashboardView(spaceID: space.id)
        case .history: SpaceVersionHistoryView(spaceID: space.id)
        case .settings: SpaceSettingsTab(spaceID: space.id)
        }
    }
}

// MARK: - SpaceMessagesTab

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
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(message.senderName)
                                                .font(.caption.bold())
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Text(message.timestamp, style: .time)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                        Text(message.content)
                                            .padding(10)
                                            .background(Color.secondary.opacity(0.08))
                                            .cornerRadius(12)
                                    }
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

            HStack(spacing: 8) {
                Image(systemName: "text.bubble")
                    .foregroundStyle(.secondary)
                TextField("Message", text: $newMessage)
                    .textFieldStyle(.roundedBorder)
                Button {
                    if !newMessage.isEmpty {
                        manager.sendMessage(spaceID: spaceID, content: newMessage)
                        newMessage = ""
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
        }
    }
}

// MARK: - SpaceFilesTab

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
                    HStack(spacing: 12) {
                        Image(systemName: fileIcon(for: file.type))
                            .font(.title3)
                            .foregroundStyle(fileColor(for: file.type))
                            .frame(width: 36, height: 36)
                            .background(fileColor(for: file.type).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name)
                                .font(.subheadline.bold())
                            Text("\(file.size / 1024) KB • \(file.timestamp, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Files Shared",
                    systemImage: "doc.badge.plus",
                    description: Text("Upload files to share with your team.")
                )
            }
        }
    }

    private func fileIcon(for type: String) -> String {
        switch type.lowercased() {
        case "image", "photo", "png", "jpg", "jpeg": return "photo.fill"
        case "video", "mov", "mp4": return "video.fill"
        case "pdf": return "doc.richtext.fill"
        case "document", "doc", "docx": return "doc.text.fill"
        case "spreadsheet", "xlsx", "csv": return "tablecells.fill"
        default: return "doc.fill"
        }
    }

    private func fileColor(for type: String) -> Color {
        switch type.lowercased() {
        case "image", "photo", "png", "jpg", "jpeg": return .orange
        case "video", "mov", "mp4": return .purple
        case "pdf": return .red
        case "spreadsheet", "xlsx", "csv": return .green
        default: return .blue
        }
    }
}

// MARK: - SpaceSettingsTab

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
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.title3)
                                .foregroundStyle(roleColor(member.role))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name)
                                    .font(.subheadline.bold())
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Label(member.role.rawValue, systemImage: roleIcon(member.role))
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(roleColor(member.role).opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
                Button {
                    showingAddMember = true
                } label: {
                    Label("Add Member", systemImage: "person.badge.plus")
                }
            } header: {
                Label("Members", systemImage: "person.3.fill")
            }
        }
    }

    private func roleIcon(_ role: SpaceRole) -> String {
        switch role {
        case .owner: return "crown.fill"
        case .admin: return "shield.fill"
        case .editor: return "pencil"
        case .commenter: return "bubble.left"
        case .viewer: return "eye"
        }
    }

    private func roleColor(_ role: SpaceRole) -> Color {
        switch role {
        case .owner: return .orange
        case .admin: return .blue
        case .editor: return .green
        case .commenter: return .purple
        case .viewer: return .secondary
        }
    }
}

// MARK: - SpaceOverviewTab

struct SpaceOverviewTab: View {
    let space: CollaborationSpace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    spaceStatCard(icon: "person.3.fill", title: "Members", value: "\(space.members.count)", color: .blue)
                    spaceStatCard(icon: "doc.fill", title: "Files", value: "\(space.sharedFiles.count)", color: .green)
                    spaceStatCard(icon: "bubble.left.fill", title: "Messages", value: "\(space.messages.count)", color: .purple)
                }
                .padding(.horizontal)

                if space.description.isEmpty {
                    HStack {
                        Image(systemName: "text.alignleft")
                            .foregroundStyle(.secondary)
                        Text("No description provided.")
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    Text(space.description)
                        .padding(.horizontal)
                }

                Divider()

                HStack {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Activity Feed")
                        .font(.headline)
                }
                .padding(.horizontal)

                if space.activityFeed.isEmpty {
                    ContentUnavailableView(
                        "No Activity Yet",
                        systemImage: "clock.badge.questionmark",
                        description: Text("Activity will appear here as team members collaborate.")
                    )
                    .padding(.horizontal)
                } else {
                    ForEach(space.activityFeed) { log in
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.action)
                                    .font(.subheadline)
                                Text("\(log.userName) • \(log.timestamp, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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

    private func spaceStatCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - SpaceObjectsList

struct SpaceObjectsList: View {
    let title: String
    let ids: [UUID]
    let icon: String

    var body: some View {
        List {
            if ids.isEmpty {
                ContentUnavailableView(
                    "No \(title)",
                    systemImage: icon,
                    description: Text("Add \(title.lowercased()) to this space to get started.")
                )
            } else {
                ForEach(ids, id: \.self) { id in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .foregroundStyle(.blue)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Object \(id.uuidString.prefix(8))")
                                .font(.subheadline)
                            Text(id.uuidString)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SpaceTemplatePickerView

struct SpaceTemplatePickerView: View {
    @Binding var selectedTemplate: SpaceTemplate?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(SpaceTemplate.allTemplates) { template in
                    Button {
                        selectedTemplate = template
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: template.icon)
                                .font(.title)
                                .foregroundStyle(template.color)
                                .frame(width: 52, height: 52)
                                .background(template.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                            Text(template.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)

                            Text(template.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    selectedTemplate?.name == template.name ? template.color : Color.secondary.opacity(0.2),
                                    lineWidth: selectedTemplate?.name == template.name ? 2 : 1
                                )
                        )
                        .background(
                            selectedTemplate?.name == template.name ? template.color.opacity(0.04) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}
