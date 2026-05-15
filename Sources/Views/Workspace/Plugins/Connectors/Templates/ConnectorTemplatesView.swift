import SwiftUI

struct ConnectorTemplatesView: View {
    @State private var templates: [ConnectorTemplateItem] = []
    @State private var searchText = ""
    @State private var selectedCategory: ConnectorCategory?

    fileprivate var filteredTemplates: [ConnectorTemplateItem] {
        templates.filter { template in
            let matchesSearch = searchText.isEmpty || template.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || template.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        categoryChip(nil, label: "All")
                        ForEach(ConnectorCategory.allCases, id: \.self) { cat in
                            categoryChip(cat, label: cat.rawValue.capitalized)
                        }
                    }
                }
            }

            Section("Templates (\(filteredTemplates.count))") {
                ForEach(filteredTemplates) { template in
                    NavigationLink(destination: ConnectorBuilderView()) {
                        HStack(spacing: 12) {
                            Image(systemName: template.icon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.name)
                                    .font(.headline)
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                HStack {
                                    Label(template.category.rawValue.capitalized, systemImage: "tag")
                                    Label(template.complexity.rawValue.capitalized, systemImage: "gauge.medium")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Connector Templates")
        .searchable(text: $searchText, prompt: "Search templates")
        .task { loadTemplates() }
    }

    private func categoryChip(_ category: ConnectorCategory?, label: String) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? Color.blue : Color(uiColor: .secondarySystemBackground))
                .foregroundStyle(selectedCategory == category ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func loadTemplates() {
        // Templates are loaded from a registry or user-created; start empty.
    }
}

private struct ConnectorTemplateItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: ConnectorCategory
    let complexity: Complexity
}

private enum ConnectorCategory: String, CaseIterable { case api, events, data, storage, messaging, auth }
private enum Complexity: String { case simple, medium, advanced }
