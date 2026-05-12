

import SwiftUI

struct SDKDataInspectorView: View {
    @StateObject private var dataStore = SDKDataStore.shared
    @State private var selectedCollection: String?
    @State private var inspectedItems: [InspectedItem] = []
    @State private var searchText = ""

    var body: some View {
        List {
            Section("Storage Overview") {
                LabeledContent("Initialization") {
                    Image(systemName: dataStore.isInitialized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(dataStore.isInitialized ? Color.green : Color.red)
                }
                LabeledContent("Total Records") {
                    Text("\(dataStore.totalRecords)")
                        .font(.body.monospaced())
                        .bold()
                }
            }

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
                                Label(name, systemImage: "folder")
                                    .font(.subheadline.monospaced())
                                Spacer()
                                Text("\(count) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if let selected = selectedCollection {
                Section(selected) {
                    let filtered = searchText.isEmpty ? inspectedItems :
                        inspectedItems.filter { $0.preview.localizedCaseInsensitiveContains(searchText) }

                    if filtered.isEmpty {
                        ContentUnavailableView("No Records", systemImage: "doc.text.magnifyingglass", description: Text("No items found in this collection."))
                    } else {
                        ForEach(filtered) { item in
                            InspectedItemRow(item: item)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search records")
        .navigationTitle("Data Inspector")
    }

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
        default: break
        }
    }
}

// MARK: - Private Subviews

private struct InspectedItemRow: View {
    let item: InspectedItem
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.id.uuidString.prefix(8).description)
                    .font(.caption2.monospaced())
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

private struct InspectedItem: Identifiable, Sendable {
    let id: UUID, preview: String, updatedAt: Date
}
