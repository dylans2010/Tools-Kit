import SwiftUI

/// Data Inspector — inspect stored SDK models, debug persistence, view collection stats.
struct SDKDataInspectorView: View {
    @StateObject private var dataStore = SDKDataStore.shared
    @State private var selectedCollection: String?
    @State private var inspectedItems: [InspectedItem] = []
    @State private var searchText = ""

    var body: some View {
        List {
            overviewSection
            collectionsSection
            if let selected = selectedCollection {
                itemsSection(for: selected)
            }
        }
        .searchable(text: $searchText, prompt: "Search data")
        .navigationTitle("Data Inspector")
    }

    // MARK: - Overview

    private var overviewSection: some View {
        Section("Storage Overview") {
            HStack {
                Label("Initialized", systemImage: "cylinder.fill")
                Spacer()
                Image(systemName: dataStore.isInitialized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(dataStore.isInitialized ? .green : .red)
            }
            HStack {
                Label("Total Records", systemImage: "number")
                Spacer()
                Text("\(dataStore.totalRecords)")
                    .font(.system(.body, design: .monospaced))
                    .bold()
            }
        }
    }

    // MARK: - Collections

    private var collectionsSection: some View {
        Section("Collections") {
            let stats = dataStore.collectionStats()
            if stats.isEmpty {
                Text("No collections found").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(stats.sorted(by: { $0.key < $1.key }), id: \.key) { name, count in
                    Button {
                        selectedCollection = name
                        loadItems(for: name)
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(name)
                                .font(.system(.subheadline, design: .monospaced))
                            Spacer()
                            Text("\(count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if selectedCollection == name {
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Items

    private func itemsSection(for collection: String) -> some View {
        Section("\(collection) Items") {
            let filtered = searchText.isEmpty ? inspectedItems :
                inspectedItems.filter { $0.preview.localizedCaseInsensitiveContains(searchText) }

            if filtered.isEmpty {
                Text("No items").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(filtered) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.id.uuidString.prefix(8) + "...")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(item.updatedAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text(item.preview)
                            .font(.caption)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Load Items

    private func loadItems(for collection: String) {
        inspectedItems = []

        switch collection {
        case "SDKMailMessage":
            inspectedItems = SDKDataStore.shared.fetchAll(SDKMailMessage.self).map {
                InspectedItem(id: $0.id, preview: "From: \($0.from) | Subject: \($0.subject)", updatedAt: $0.updatedAt)
            }
        case "SDKNotebook":
            inspectedItems = SDKDataStore.shared.fetchAll(SDKNotebook.self).map {
                InspectedItem(id: $0.id, preview: "\($0.title) (\($0.pages.count) pages)", updatedAt: $0.updatedAt)
            }
        case "SDKMeetSession":
            inspectedItems = SDKDataStore.shared.fetchAll(SDKMeetSession.self).map {
                InspectedItem(id: $0.id, preview: "\($0.title) — \($0.status.rawValue)", updatedAt: $0.updatedAt)
            }
        case "SDKArticle":
            inspectedItems = SDKDataStore.shared.fetchAll(SDKArticle.self).map {
                InspectedItem(id: $0.id, preview: "\($0.title) (\($0.wordCount) words)", updatedAt: $0.updatedAt)
            }
        case "SDKAppDefinition":
            inspectedItems = SDKDataStore.shared.fetchAll(SDKAppDefinition.self).map {
                InspectedItem(id: $0.id, preview: "\($0.name) v\($0.version) by \($0.author)", updatedAt: $0.updatedAt)
            }
        default:
            break
        }
    }
}

private struct InspectedItem: Identifiable {
    let id: UUID
    let preview: String
    let updatedAt: Date
}
