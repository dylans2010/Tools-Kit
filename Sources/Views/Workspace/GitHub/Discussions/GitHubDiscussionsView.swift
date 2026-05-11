import SwiftUI

struct GitHubDiscussionsView: View {
    @State private var discussions: [Discussion] = []
    @State private var searchText = ""
    @State private var selectedCategory: DiscussionCategory = .general

    fileprivate var filteredDiscussions: [Discussion] {
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
        // Discussions are fetched from the repository; start empty until connected to a GitHub repo.
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
