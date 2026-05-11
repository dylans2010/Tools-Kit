import SwiftUI

struct GitHubDiscussionsView: View {
    @State private var discussions: [Discussion] = []
    @State private var searchText = ""
    @State private var selectedCategory: DiscussionCategory = .general

    var filteredDiscussions: [Discussion] {
        discussions.filter { d in
            let matchesSearch = searchText.isEmpty || d.title.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == .general || d.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(DiscussionCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: category.icon)
                                    Text(category.rawValue.capitalized)
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? Color.blue : Color(.secondarySystemBackground))
                                .foregroundStyle(selectedCategory == category ? .white : .primary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            Section("Discussions (\(filteredDiscussions.count))") {
                ForEach(filteredDiscussions) { discussion in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: discussion.isAnswered ? "checkmark.message.fill" : "message")
                                .foregroundStyle(discussion.isAnswered ? .green : .blue)
                            Text(discussion.title)
                                .font(.subheadline.bold())
                        }
                        Text(discussion.preview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        HStack {
                            Label(discussion.author, systemImage: "person")
                            Spacer()
                            Label("\(discussion.replyCount)", systemImage: "bubble.right")
                            Label("\(discussion.upvotes)", systemImage: "arrow.up")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Discussions")
        .searchable(text: $searchText, prompt: "Search discussions")
        .task { loadDiscussions() }
    }

    private func loadDiscussions() {
        discussions = [
            Discussion(title: "Best practices for SDK plugin development", category: .general, author: "dev_user", preview: "What are the recommended patterns for building SDK plugins?", replyCount: 12, upvotes: 8, isAnswered: true),
            Discussion(title: "Feature request: Real-time collaboration", category: .ideas, author: "collab_fan", preview: "It would be great to have real-time editing support in the workspace.", replyCount: 23, upvotes: 45, isAnswered: false),
            Discussion(title: "How to configure custom connectors?", category: .qAndA, author: "new_dev", preview: "I'm trying to set up a custom REST connector but having trouble with auth.", replyCount: 5, upvotes: 3, isAnswered: true),
            Discussion(title: "Showcase: My AI-powered workflow", category: .showAndTell, author: "ai_builder", preview: "Built an automated workflow using the SDK that generates reports.", replyCount: 8, upvotes: 15, isAnswered: false),
            Discussion(title: "Performance improvements in v2.0", category: .announcements, author: "team_lead", preview: "Highlights of performance improvements in the latest release.", replyCount: 4, upvotes: 32, isAnswered: false),
        ]
    }
}

private struct Discussion: Identifiable {
    let id = UUID()
    let title: String
    let category: DiscussionCategory
    let author: String
    let preview: String
    let replyCount: Int
    let upvotes: Int
    let isAnswered: Bool
}

private enum DiscussionCategory: String, CaseIterable {
    case general, announcements, ideas, qAndA = "Q&A", showAndTell = "Show & Tell"

    var icon: String {
        switch self {
        case .general: return "bubble.left.and.bubble.right"
        case .announcements: return "megaphone"
        case .ideas: return "lightbulb"
        case .qAndA: return "questionmark.circle"
        case .showAndTell: return "star"
        }
    }
}
