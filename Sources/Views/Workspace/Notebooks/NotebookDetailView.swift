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
            VStack(spacing: 14) {
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
        .searchable(text: $searchText, prompt: "Search folders/pages")
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
        .onChange(of: photoPickerItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { notebookArtwork = image }
                }
            }
        }
    }

    private var heroCard: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(liveNotebook.name)
                            .font(.title3.weight(.bold))
                        Text("Cleaner workspace, faster navigation, and richer notebook intelligence.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if supportsImagePlayground {
                        Button {
                            showingImagePlayground = true
                        } label: {
                            Image(systemName: "sparkles")
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Generate Notebook Artwork")
                    }
                }

                if let notebookArtwork {
                    Image(uiImage: notebookArtwork)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [.indigo.opacity(0.32), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 100)
                        .overlay(
                            Label("Notebook Cover", systemImage: "photo.on.rectangle")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        )
                }

                HStack(spacing: 8) {
                    if supportsImagePlayground {
                        Button("Image Playground", systemImage: "sparkles") {
                            showingImagePlayground = true
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Label("Upload Cover", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var statsCard: some View {
        WorkspaceSurfaceCard {
            HStack(spacing: 10) {
                statView("Folders", value: "\(liveNotebook.folders.count)", color: .indigo)
                statView("Pages", value: "\(totalPages)", color: .blue)
                statView("Updated", value: liveNotebook.updatedAt.formatted(date: .abbreviated, time: .omitted), color: .teal)
            }
        }
    }

    private var quickToolsSection: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notebook Tools")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        quickTool("Create Folder", icon: "folder.badge.plus") { showingCreateFolder = true }
                        quickTool("Starter Folder", icon: "folder.fill.badge.plus") { addStarterFolder() }
                        quickTool("Duplicate First", icon: "doc.on.doc") { duplicateFirstFolder() }
                        quickTool("Sort A–Z", icon: "textformat") { selectedSort = .alphabetical }
                        quickTool("Sort by Pages", icon: "number") { selectedSort = .pages }
                        quickTool("Newest First", icon: "clock.arrow.circlepath") { selectedSort = .recent }
                        quickTool("Toggle Non-Empty", icon: "line.3.horizontal.decrease.circle") { showOnlyNonEmptyFolders.toggle() }
                        quickTool("Clean Empty", icon: "trash.slash") { removeEmptyFolders() }
                        quickTool("AI Insights", icon: "brain.head.profile") { showingAISheet = true }
                        quickTool("Integrations", icon: "puzzlepiece.extension") { showingIntegrations = true }
                        if supportsImagePlayground {
                            quickTool("AI Artwork", icon: "sparkles") { showingImagePlayground = true }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Folders")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(filteredFolders) { folder in
                    NavigationLink {
                        FolderDetailView(folder: folder, notebookID: notebook.id)
                    } label: {
                        WorkspaceSurfaceCard {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.yellow)
                                    .frame(width: 38, height: 38)
                                    .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(folder.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(folder.pages.count) pages")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Menu {
                                    Button("Duplicate Folder") { duplicateFolder(folder) }
                                    Button("Delete Folder", role: .destructive) { deleteFolder(folder) }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(.secondary)
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
                    Text("Notebook AI")
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

    private func quickTool(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.14), in: Capsule())
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
                    "\($0.name) | pages: \($0.pages.count)"
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
