import SwiftUI

struct NotebooksHomeView: View {
    @StateObject private var manager = NotebooksManager.shared
    @State private var showingCreate = false
    @State private var showingIntegrations = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    actionButton("New Notebook", icon: "plus.rectangle.on.rectangle", color: .indigo) {
                        showingCreate = true
                    }
                    actionButton("Integrations", icon: "puzzlepiece.extension", color: .purple) {
                        showingIntegrations = true
                    }
                }
                .padding(.horizontal)

                if manager.notebooks.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Notebooks",
                        message: "Create your first notebook to start organizing your thoughts.",
                        action: { showingCreate = true },
                        actionLabel: "Create Notebook"
                    )
                } else {
                    Text("Your Notebooks")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVStack(spacing: 12) {
                        ForEach(manager.notebooks) { notebook in
                            NavigationLink {
                                NotebookDetailView(notebook: notebook)
                            } label: {
                                NotebookRow(notebook: notebook)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Notebooks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateNotebookView()
        }
        .sheet(isPresented: $showingIntegrations) {
            NavigationStack { IntegrationsView() }
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

private struct NotebookRow: View {
    let notebook: Notebook
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "book.closed.fill")
                .font(.title2)
                .foregroundColor(.indigo)
                .frame(width: 44, height: 44)
                .background(Color.indigo.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(notebook.name).font(.headline)
                Text("\(notebook.folders.count) folders · \(notebook.folders.flatMap(\.pages).count) pages")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}
