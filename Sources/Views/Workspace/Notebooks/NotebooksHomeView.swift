import SwiftUI

struct NotebooksHomeView: View {
    @StateObject private var manager = NotebooksManager.shared
    @State private var showingCreate = false
    @State private var showingIntegrations = false
    @State private var showingAISheet = false
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var aiInsights: NotebooksManager.AINotebookInsights?
    @State private var editingNotebook: Notebook?
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var notebookToDelete: Notebook?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                summaryCard
                compactHeader
                notebooksSection
            }
            .padding(16)
        }
        .navigationTitle("Notebooks")
        .sheet(isPresented: $showingCreate) { CreateNotebookView() }
        .sheet(isPresented: $showingIntegrations) { NavigationStack { IntegrationsView() } }
        .sheet(isPresented: $showingAISheet) { aiSheet }
        .sheet(isPresented: $showingEditSheet) {
            if let notebook = editingNotebook {
                EditNotebookSheet(notebook: notebook, manager: manager, isPresented: $showingEditSheet)
            }
        }
        .alert("Delete Notebook", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { notebookToDelete = nil }
            Button("Delete", role: .destructive) {
                if let notebook = notebookToDelete {
                    manager.deleteNotebook(notebook)
                    notebookToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(notebookToDelete?.name ?? "")\"? This action cannot be undone.")
        }
    }

    private var compactHeader: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notebooks")
                            .font(.title3.bold())
                        Text("Keep ideas organized with less clutter.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        showingIntegrations = true
                    } label: {
                        Image(systemName: "puzzlepiece.extension")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.bordered)
                    Button {
                        showingAISheet = true
                    } label: {
                        Image(systemName: "sparkles")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.bordered)
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.borderedProminent)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        quickAction("New Notebook", icon: "book.badge.plus") { showingCreate = true }
                        quickAction("Add Folder", icon: "folder.badge.plus") { showingCreate = true }
                        quickAction("Integrations", icon: "puzzlepiece.extension") { showingIntegrations = true }
                        quickAction("AI Ideas", icon: "sparkles") { showingAISheet = true }
                        quickAction("Templates", icon: "square.grid.2x2") { showingCreate = true }
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        WorkspaceSurfaceCard {
            HStack(spacing: 10) {
                summaryStat("Notebooks", value: "\(manager.notebooks.count)", icon: "book.closed.fill")
                summaryStat("Folders", value: "\(manager.notebooks.reduce(0) { $0 + $1.folders.count })", icon: "folder.fill")
                summaryStat("Pages", value: "\(manager.notebooks.reduce(0) { $0 + $1.folders.flatMap(\ .pages).count })", icon: "doc.richtext")
            }
        }
    }

    private func summaryStat(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func quickAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var notebooksSection: some View {
        if manager.notebooks.isEmpty {
            EmptyStateView(
                icon: "book.closed",
                title: "No Notebooks",
                message: "Create your first notebook to start writing and organizing notes.",
                action: { showingCreate = true },
                actionLabel: "Create Notebook"
            )
        } else {
            VStack(spacing: 10) {
                ForEach(manager.notebooks) { notebook in
                    NavigationLink {
                        NotebookDetailView(notebook: notebook)
                    } label: {
                        NotebookRow(notebook: notebook)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            editingNotebook = notebook
                            showingEditSheet = true
                        } label: {
                            Label("Edit Notebook", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            notebookToDelete = notebook
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var aiSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Note Tools")
                        .font(.headline)
                    Text("Write naturally. You can give rough thoughts and AI will infer structure.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("e.g. turn this brainstorm into clear notes", text: $aiPrompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 8) {
                        aiAction("Summarize", icon: "text.alignleft") {
                            runAI(using: "Summarize this naturally and keep key ideas.")
                        }
                        aiAction("Tags", icon: "tag.fill") {
                            runAI(using: "Suggest tags and categories from this note.")
                        }
                        aiAction("Study", icon: "brain.head.profile") {
                            runAI(using: "Turn this into a study guide with recall prompts.")
                        }
                        aiAction("Outline", icon: "list.bullet.rectangle") {
                            runAI(using: "Turn this into a structured outline with sections.")
                        }
                    }

                    HStack {
                        Button("Analyze", action: runAI)
                            .buttonStyle(.borderedProminent)
                            .disabled(aiLoading || aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Spacer()
                    }

                    if aiLoading {
                        WorkspaceSkeletonLine()
                        WorkspaceSkeletonLine(widthRatio: 0.8)
                    } else if let aiError {
                        Text(aiError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if let aiInsights {
                        Text(aiInsights.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        insightList("Tags", aiInsights.tags)
                        insightList("Related", aiInsights.relatedNotes)
                    }
                }
                .padding(16)
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingAISheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func insightList(_ title: String, _ values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
            ForEach(values, id: \.self) { item in
                Text("• \(item)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func runAI() {
        runAI(using: aiPrompt)
    }

    private func runAI(using input: String) {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                let context = manager.notebooks.map {
                    "\($0.name) | folders: \($0.folders.count) | pages: \($0.folders.flatMap(\.pages).count) | updated: \($0.updatedAt)"
                }.joined(separator: "\n")
                let insights = try await manager.generateNoteInsights(noteContent: prompt, notebookContext: context)
                await MainActor.run {
                    aiInsights = insights
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Couldn’t analyze that yet. Natural language input is supported—try again with any phrasing."
                    aiLoading = false
                }
            }
        }
    }

    private func aiAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }
}

private struct NotebookRow: View {
    let notebook: Notebook

    var body: some View {
        WorkspaceSurfaceCard {
            HStack(spacing: 12) {
                Image(systemName: notebook.iconName)
                    .foregroundStyle(Color(hex: notebook.colorHex))
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: notebook.colorHex).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(notebook.name)
                        .font(.headline)
                    Text("\(notebook.folders.count) Folders · \(notebook.folders.flatMap(\.pages).count) Pages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct EditNotebookSheet: View {
    let notebook: Notebook
    let manager: NotebooksManager
    @Binding var isPresented: Bool
    @State private var name: String
    @State private var iconName: String
    @State private var colorHex: String

    private let iconOptions = [
        "book.closed", "book.fill", "text.book.closed", "magazine",
        "bookmark.fill", "star.fill", "heart.fill", "folder.fill",
        "doc.text.fill", "pencil.circle.fill", "lightbulb.fill", "brain.head.profile"
    ]

    private let colorOptions = [
        "#4F46E5", "#2563EB", "#7C3AED", "#DB2777",
        "#DC2626", "#EA580C", "#D97706", "#16A34A",
        "#0D9488", "#0891B2", "#4B5563", "#78716C"
    ]

    init(notebook: Notebook, manager: NotebooksManager, isPresented: Binding<Bool>) {
        self.notebook = notebook
        self.manager = manager
        self._isPresented = isPresented
        self._name = State(initialValue: notebook.name)
        self._iconName = State(initialValue: notebook.iconName)
        self._colorHex = State(initialValue: notebook.colorHex)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Notebook Name", text: $name)
                        .font(.headline)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                iconName = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        iconName == icon
                                            ? Color.accentColor.opacity(0.15)
                                            : Color(.tertiarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(iconName == icon ? Color.accentColor : .clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: colorHex == hex ? 3 : 0)
                                    )
                                    .overlay {
                                        if colorHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Info") {
                    LabeledContent("Folders", value: "\(notebook.folders.count)")
                    LabeledContent("Pages", value: "\(notebook.folders.flatMap(\.pages).count)")
                    LabeledContent("Created", value: notebook.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .navigationTitle("Edit Notebook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = notebook
                        updated.name = name.isEmpty ? "Untitled Notebook" : name
                        updated.iconName = iconName
                        updated.colorHex = colorHex
                        manager.updateNotebook(updated)
                        isPresented = false
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
