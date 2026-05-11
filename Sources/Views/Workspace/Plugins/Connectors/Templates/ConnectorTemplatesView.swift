import SwiftUI

struct ConnectorTemplatesView: View {
    @State private var templates: [ConnectorTemplate] = []
    @State private var searchText = ""
    @State private var selectedCategory: ConnectorCategory?

    var filteredTemplates: [ConnectorTemplate] {
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
                .background(selectedCategory == category ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(selectedCategory == category ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func loadTemplates() {
        templates = [
            ConnectorTemplate(name: "REST API", description: "Generic REST API connector with OAuth2 support", icon: "globe", category: .api, complexity: .medium),
            ConnectorTemplate(name: "GraphQL", description: "Query GraphQL endpoints with schema introspection", icon: "circle.grid.cross", category: .api, complexity: .advanced),
            ConnectorTemplate(name: "Webhook Receiver", description: "Receive and process incoming webhook events", icon: "antenna.radiowaves.left.and.right", category: .events, complexity: .simple),
            ConnectorTemplate(name: "Database", description: "Connect to SQL databases with query builder", icon: "cylinder", category: .data, complexity: .advanced),
            ConnectorTemplate(name: "File Storage", description: "Read and write files from cloud storage providers", icon: "folder.fill", category: .storage, complexity: .medium),
            ConnectorTemplate(name: "Email SMTP", description: "Send emails through SMTP servers", icon: "envelope", category: .messaging, complexity: .simple),
            ConnectorTemplate(name: "WebSocket", description: "Real-time bidirectional communication", icon: "bolt.horizontal", category: .events, complexity: .medium),
            ConnectorTemplate(name: "OAuth2 Provider", description: "Authenticate with OAuth2 identity providers", icon: "key", category: .auth, complexity: .medium),
        ]
    }
}

private struct ConnectorTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: ConnectorCategory
    let complexity: Complexity
}

private enum ConnectorCategory: String, CaseIterable { case api, events, data, storage, messaging, auth }
private enum Complexity: String { case simple, medium, advanced }
