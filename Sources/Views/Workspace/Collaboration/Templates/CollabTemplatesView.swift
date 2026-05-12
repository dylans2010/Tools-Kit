import SwiftUI

struct CollabTemplatesView: View {
    @State private var templates: [WorkspaceTemplate] = []
    @State private var searchText = ""
    @State private var selectedCategory: WTemplateCategory?

    fileprivate var filteredTemplates: [WorkspaceTemplate] {
        templates.filter { t in
            let matchesSearch = searchText.isEmpty || t.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || t.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        categoryChip(nil, label: "All")
                        ForEach(WTemplateCategory.allCases, id: \.self) { cat in
                            categoryChip(cat, label: cat.rawValue.capitalized)
                        }
                    }
                }
            }

            Section("Templates (\(filteredTemplates.count))") {
                ForEach(filteredTemplates) { template in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: template.icon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading) {
                                Text(template.name)
                                    .font(.headline)
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        HStack {
                            Label(template.category.rawValue.capitalized, systemImage: "tag")
                            Spacer()
                            Label("\(template.usageCount) uses", systemImage: "person.2")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        Button("Use Template") {}
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Templates")
        .searchable(text: $searchText, prompt: "Search templates")
        .task { loadTemplates() }
    }

    private func categoryChip(_ category: WTemplateCategory?, label: String) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(selectedCategory == category ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func loadTemplates() {
        // Templates are user-created or loaded from a registry; start empty.
    }
}

private struct WorkspaceTemplate: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: WTemplateCategory
    let usageCount: Int
}

private enum WTemplateCategory: String, CaseIterable, Sendable {
    case project, design, documentation, meeting, engineering
}
