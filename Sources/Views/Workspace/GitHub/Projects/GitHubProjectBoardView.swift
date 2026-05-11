import SwiftUI

struct GitHubProjectBoardView: View {
    @State private var columns: [ProjectColumn] = []
    @State private var showingAddColumn = false
    @State private var newColumnName = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(columns) { column in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(column.name)
                                .font(.headline)
                            Text("\(column.cards.count)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                            Spacer()
                            Button { } label: {
                                Image(systemName: "plus")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)

                        ForEach(column.cards) { card in
                            projectCardView(card)
                        }

                        Spacer()
                    }
                    .frame(width: 280)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showingAddColumn = true
                } label: {
                    VStack {
                        Image(systemName: "plus.rectangle")
                            .font(.title2)
                        Text("Add Column")
                            .font(.caption)
                    }
                    .frame(width: 200, height: 100)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Project Board")
        .alert("New Column", isPresented: $showingAddColumn) {
            TextField("Column Name", text: $newColumnName)
            Button("Add") {
                if !newColumnName.isEmpty {
                    columns.append(ProjectColumn(name: newColumnName, cards: []))
                    newColumnName = ""
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .task { loadBoard() }
    }

    private func projectCardView(_ card: ProjectCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(card.title)
                .font(.subheadline.bold())
            if !card.description.isEmpty {
                Text(card.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack {
                if let assignee = card.assignee {
                    Label(assignee, systemImage: "person")
                }
                Spacer()
                if let priority = card.priority {
                    Text(priority)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor(priority).opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .padding(.horizontal, 8)
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .blue
        default: return .secondary
        }
    }

    private func loadBoard() {
        columns = [
            ProjectColumn(name: "To Do", cards: [
                ProjectCard(title: "Implement user notifications", description: "Add push notification support for workspace events", assignee: "dev1", priority: "High"),
                ProjectCard(title: "Update API documentation", description: "Document new SDK endpoints", assignee: nil, priority: "Medium"),
                ProjectCard(title: "Design review for settings page", description: "", assignee: "designer", priority: "Low"),
            ]),
            ProjectColumn(name: "In Progress", cards: [
                ProjectCard(title: "Connector health dashboard", description: "Real-time monitoring for active connectors", assignee: "dev2", priority: "High"),
                ProjectCard(title: "Refactor plugin sandbox", description: "Improve memory management in plugin runtime", assignee: "dev3", priority: "Medium"),
            ]),
            ProjectColumn(name: "In Review", cards: [
                ProjectCard(title: "Fix dark mode colors", description: "Adjust theme colors for better contrast", assignee: "dev1", priority: "Medium"),
            ]),
            ProjectColumn(name: "Done", cards: [
                ProjectCard(title: "SDK v2.0 release", description: "Published new SDK version with unified API", assignee: "team", priority: nil),
                ProjectCard(title: "CI pipeline optimization", description: "Reduced build time by 40%", assignee: "devops", priority: nil),
            ]),
        ]
    }
}

private struct ProjectColumn: Identifiable {
    let id = UUID()
    let name: String
    var cards: [ProjectCard]
}

private struct ProjectCard: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let assignee: String?
    let priority: String?
}
