import SwiftUI
import PhotosUI
#if canImport(ImagePlayground)
import ImagePlayground
#endif

struct NotebookDetailView: View {
    let notebook: Notebook
    @StateObject private var manager = NotebooksManager.shared

    @State private var showingCreateFolder = false
    @State private var showingIntegrations = false
    @State private var showingAISheet = false
    @State private var showingImagePlayground = false
    @State private var searchText = ""
    @State private var showOnlyNonEmptyFolders = false
    @State private var selectedSort: FolderSort = .recent
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var aiInsights: NotebooksManager.AINotebookInsights?
    @State private var notebookArtwork: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @AppStorage("notebookCoverData") private var savedCoverData: Data = Data()
    @State private var showingToolsDropdown = false

    private enum FolderSort: String, CaseIterable, Identifiable {
        case recent = "Recent"
        case alphabetical = "A–Z"
        case pages = "Most Pages"
        var id: String { rawValue }
    }

    private var liveNotebook: Notebook {
        manager.notebooks.first(where: { $0.id == notebook.id }) ?? notebook
    }

    private var filteredFolders: [NotebookFolder] {
        var folders = liveNotebook.folders
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            folders = folders.filter {
                $0.name.localizedCaseInsensitiveContains(text) ||
                $0.pages.contains(where: { $0.title.localizedCaseInsensitiveContains(text) || $0.content.localizedCaseInsensitiveContains(text) })
            }
        }
        if showOnlyNonEmptyFolders {
            folders = folders.filter { !$0.pages.isEmpty }
        }
        switch selectedSort {
        case .recent:
            folders.sort { $0.createdAt > $1.createdAt }
        case .alphabetical:
            folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .pages:
            folders.sort { $0.pages.count > $1.pages.count }
        }
        return folders
    }

    private var totalPages: Int {
        liveNotebook.folders.flatMap(\.pages).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                statsCard
                quickToolsSection
                foldersSection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(liveNotebook.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search Folders or Pages")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort", selection: $selectedSort) {
                        ForEach(FolderSort.allCases) { sort in
                            Text(sort.rawValue).tag(sort)
                        }
                    }
                    Toggle("Only Non-Empty Folders", isOn: $showOnlyNonEmptyFolders)
                    Button("Remove Empty Folders", role: .destructive, action: removeEmptyFolders)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }

                Button { showingCreateFolder = true } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateFolder) {
            CreateFolderView(notebookID: notebook.id)
        }
        .sheet(isPresented: $showingIntegrations) {
            NavigationStack { IntegrationsView() }
        }
        .sheet(isPresented: $showingAISheet) {
            aiInsightsSheet
        }
        .modifier(ImagePlaygroundNotebookModifier(
            isPresented: $showingImagePlayground,
            concept: "\(liveNotebook.name) clean notebook cover with productivity visuals",
            onResult: handleImagePlaygroundResult
        ))
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        notebookArtwork = image
                        saveCoverToAppStorage(image)
                    }
                }
            }
        }
        .onAppear {
            loadCoverFromAppStorage()
        }
    }

    private var heroCard: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .bottomLeading) {
                    if let notebookArtwork {
                        Image(uiImage: notebookArtwork)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .indigo.opacity(0.35),
                                        .blue.opacity(0.25),
                                        .purple.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 160)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "book.closed.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("Notebook Cover")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            )
                    }

                    // Gradient overlay for text readability
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Title overlay
                    VStack(alignment: .leading, spacing: 4) {
                        Text(liveNotebook.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("\(liveNotebook.folders.count) Folders · \(totalPages) Pages")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(14)
                }

                HStack(spacing: 8) {
                    Text("Updated \(liveNotebook.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.tertiarySystemBackground), in: Capsule())

                    Spacer()

                    if supportsImagePlayground {
                        Button {
                            showingImagePlayground = true
                        } label: {
                            Image(systemName: "apple.intelligence")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)
                        .accessibilityLabel("Generate Notebook Artwork")
                    }

                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Image(systemName: "photo.badge.plus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                }
            }
        }
    }

    private var statsCard: some View {
        WorkspaceSurfaceCard {
            HStack(spacing: 10) {
                modernStatView("Folders", value: "\(liveNotebook.folders.count)", icon: "folder.fill", color: .indigo)
                modernStatView("Pages", value: "\(totalPages)", icon: "doc.text.fill", color: .blue)
                modernStatView("Updated", value: liveNotebook.updatedAt.formatted(date: .abbreviated, time: .omitted), icon: "clock.fill", color: .teal)
            }
        }
    }

    private var quickToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Notebook Tools", systemImage: "wrench.and.screwdriver")
                    .font(.headline)
                Spacer()
                Text("\(liveNotebook.folders.count) Folders")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground), in: Capsule())
            }
            .padding(.horizontal, 4)

            DisclosureGroup(isExpanded: $showingToolsDropdown) {
                VStack(spacing: 2) {
                    toolDropdownItem("Add Folder", icon: "folder.badge.plus", color: .blue) { showingCreateFolder = true }
                    toolDropdownItem("Add Starter Folder", icon: "folder.fill.badge.plus", color: .indigo) { addStarterFolder() }
                    toolDropdownItem("Duplicate First Folder", icon: "doc.on.doc", color: .purple) { duplicateFirstFolder() }
                    Divider().padding(.vertical, 4)
                    toolDropdownItem("Sort Alphabetically", icon: "textformat.abc", color: .orange) { selectedSort = .alphabetical }
                    toolDropdownItem("Sort by Page Count", icon: "number", color: .teal) { selectedSort = .pages }
                    toolDropdownItem("Sort by Recent", icon: "clock.arrow.circlepath", color: .cyan) { selectedSort = .recent }
                    Divider().padding(.vertical, 4)
                    toolDropdownItem("Remove Empty Folders", icon: "trash.slash", color: .red) { removeEmptyFolders() }
                    toolDropdownItem("AI Notebook Tools", icon: "brain.head.profile", color: .green) { showingAISheet = true }
                    toolDropdownItem("Integrations", icon: "puzzlepiece.extension", color: .mint) { showingIntegrations = true }
                }
                .padding(.top, 8)
            } label: {
                Label("Quick Actions", systemImage: "bolt.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .tint(.accentColor)
        }
    }

    private func toolDropdownItem(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var foldersSection: some View {
        if filteredFolders.isEmpty {
            EmptyStateView(
                icon: "folder",
                title: "No Matching Folders",
                message: searchText.isEmpty ? "Create a folder to organize your pages." : "Try a different search or filter.",
                action: { showingCreateFolder = true },
                actionLabel: "Create Folder"
            )
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Folders", systemImage: "folder.fill")
                        .font(.headline)
                    Spacer()
                    Text("\(filteredFolders.count) of \(liveNotebook.folders.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                ForEach(filteredFolders) { folder in
                    NavigationLink {
                        FolderDetailView(folder: folder, notebookID: notebook.id)
                    } label: {
                        WorkspaceSurfaceCard {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [.yellow.opacity(0.3), .orange.opacity(0.15)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(.orange)
                                        .font(.system(size: 18))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(folder.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 6) {
                                        Label("\(folder.pages.count)", systemImage: "doc.text")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        if let latestPage = folder.pages.sorted(by: { $0.updatedAt > $1.updatedAt }).first {
                                            Text("·")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text(latestPage.updatedAt.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }

                                Spacer()

                                Menu {
                                    Button("Duplicate Folder", systemImage: "doc.on.doc") { duplicateFolder(folder) }
                                    Button("Delete Folder", systemImage: "trash", role: .destructive) { deleteFolder(folder) }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 30, height: 30)
                                        .background(Color(.tertiarySystemBackground), in: Circle())
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var aiInsightsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notebook Assist")
                        .font(.headline)
                    Text("Ask in natural language. AI will generate summaries, ideas, tags, and related note links.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("e.g. summarize this notebook and suggest next steps", text: $aiPrompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 8) {
                        quickAISheetAction("Summarize", icon: "text.alignleft") {
                            runAI(prompt: "Summarize the notebook and identify important gaps.")
                        }
                        quickAISheetAction("Organize", icon: "square.grid.2x2") {
                            runAI(prompt: "Propose better folder organization and priorities.")
                        }
                        quickAISheetAction("Study Plan", icon: "graduationcap") {
                            runAI(prompt: "Turn notebook topics into a study plan with milestones.")
                        }
                    }

                    Button("Analyze Notebook") {
                        runAI(prompt: aiPrompt)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(aiLoading)

                    if aiLoading {
                        WorkspaceSkeletonLine()
                        WorkspaceSkeletonLine(widthRatio: 0.8)
                    } else if let aiError {
                        Text(aiError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if let aiInsights {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(aiInsights.summary)
                                .font(.subheadline)
                            insightList("Expanded Ideas", aiInsights.expandedIdeas)
                            insightList("Tags", aiInsights.tags)
                            insightList("Related Notes", aiInsights.relatedNotes)
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Notebook Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingAISheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func statView(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func modernStatView(_ label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            color.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    private func quickTool(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func modernQuickTool(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.12), in: Circle())
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func quickAISheetAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }

    private func insightList(_ title: String, _ values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
            ForEach(values, id: \.self) { value in
                Text("• \(value)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func runAI(prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                let context = liveNotebook.folders.map {
                    "\($0.name) | Pages: \($0.pages.count)"
                }.joined(separator: "\n")
                let insights = try await manager.generateNoteInsights(noteContent: trimmed, notebookContext: context)
                await MainActor.run {
                    aiInsights = insights
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Couldn’t generate notebook insights right now."
                    aiLoading = false
                }
            }
        }
    }

    private func addStarterFolder() {
        var updated = liveNotebook
        var folder = NotebookFolder(name: "Starter Folder")
        folder.pages = [
            NotebookPage(title: "Overview", content: "Goals, scope, and context."),
            NotebookPage(title: "Tasks", content: "- [ ] Next action\n- [ ] Follow-up\n- [ ] Review")
        ]
        updated.folders.insert(folder, at: 0)
        manager.updateNotebook(updated)
    }

    private func duplicateFirstFolder() {
        guard let first = liveNotebook.folders.first else { return }
        duplicateFolder(first)
    }

    private func duplicateFolder(_ folder: NotebookFolder) {
        var updated = liveNotebook
        var copy = folder
        copy.id = UUID()
        copy.name = "\(folder.name) Copy"
        copy.createdAt = Date()
        updated.folders.insert(copy, at: 0)
        manager.updateNotebook(updated)
    }

    private func deleteFolder(_ folder: NotebookFolder) {
        manager.deleteFolder(folder, from: notebook.id)
    }

    private func removeEmptyFolders() {
        let empties = liveNotebook.folders.filter { $0.pages.isEmpty }
        empties.forEach { manager.deleteFolder($0, from: notebook.id) }
    }

    private var supportsImagePlayground: Bool {
        if #available(iOS 18.1, *) { return true }
        return false
    }

    private func handleImagePlaygroundResult(_ url: URL) {
        if let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            notebookArtwork = image
            saveCoverToAppStorage(image)
        }
    }

    private func saveCoverToAppStorage(_ image: UIImage) {
        let key = "notebookCover_\(notebook.id.uuidString)"
        if let data = image.jpegData(compressionQuality: 0.7) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadCoverFromAppStorage() {
        let key = "notebookCover_\(notebook.id.uuidString)"
        if let data = UserDefaults.standard.data(forKey: key),
           let image = UIImage(data: data) {
            notebookArtwork = image
        }
    }
}

private struct ImagePlaygroundNotebookModifier: ViewModifier {
    @Binding var isPresented: Bool
    let concept: String
    let onResult: (URL) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.1, *) {
            content
                .imagePlaygroundSheet(
                    isPresented: $isPresented,
                    concept: concept
                ) { url in
                    onResult(url)
                }
        } else {
            content
        }
    }
}
