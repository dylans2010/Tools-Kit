import SwiftUI

struct NotebooksHomeView: View {
    @StateObject private var manager = NotebooksManager.shared
    @State private var showingCreate = false
    @State private var showingIntegrations = false
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var aiInsights: NotebooksManager.AINotebookInsights?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                aiCard
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
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Notebooks")
        .sheet(isPresented: $showingCreate) { CreateNotebookView() }
        .sheet(isPresented: $showingIntegrations) { NavigationStack { IntegrationsView() } }
    }

    private var heroCard: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notebooks")
                            .font(.title2.bold())
                        Text("Capture ideas with structured AI assistance and connected note intelligence.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        showingIntegrations = true
                    } label: {
                        Label("Integrations", systemImage: "puzzlepiece.extension")
                    }
                    .buttonStyle(.bordered)
                    Button {
                        showingCreate = true
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                HStack(spacing: 8) {
                    aiAction("Summarize", icon: "text.alignleft") {
                        runAI(using: "Summarize this note into executive bullets and a 3-line brief.")
                    }
                    aiAction("Research Tags", icon: "tag.fill") {
                        runAI(using: "Generate taxonomy tags, topics, and searchable keywords.")
                    }
                    aiAction("Study Mode", icon: "brain.head.profile") {
                        runAI(using: "Convert this note into study guide format with recall prompts.")
                    }
                }
            }
        }
    }

    private var aiCard: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("AI Note Assistant")
                    .font(.headline)
                TextField("Summarize notes, generate tags, link related ideas…", text: $aiPrompt)
                    .textFieldStyle(.roundedBorder)
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
        }
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
                    aiError = "We couldn’t analyze this note yet. Try adding more detail and run analysis again."
                    aiLoading = false
                }
            }
        }
    }

    private func aiAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
        }
        .buttonStyle(.bordered)
    }
}

private struct NotebookRow: View {
    let notebook: Notebook

    var body: some View {
        WorkspaceSurfaceCard {
            HStack(spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(.indigo)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(Color.indigo.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(notebook.name)
                        .font(.headline)
                    Text("\(notebook.folders.count) folders · \(notebook.folders.flatMap(\.pages).count) pages")
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
