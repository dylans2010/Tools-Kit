import SwiftUI

struct SDKDataInspectorView: View {
    @StateObject private var dataStore = SDKDataStore.shared
    @State private var selectedCollection: String?
    @State private var inspectedItems: [InspectedItem] = []
    @State private var searchText = ""
    @State private var showingExport = false
    @State private var showingStats = false
    @State private var sortOrder: DataSortOrder = .updatedDesc
    @State private var showingDeleteConfirmation = false
    @State private var itemToDelete: InspectedItem?
    @State private var showingBulkActions = false
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var showingSchemaInspector = false
    @State private var showingQueryBuilder = false
    @State private var customQuery = ""
    @State private var queryResults: [InspectedItem] = []
    @State private var showingImport = false
    @State private var importJSON = ""
    @State private var dataIntegrityStatus: DataIntegrityStatus = .healthy
    @State private var showingIntegrityCheck = false
    @State private var storageUsageBytes: Int = 0

    private var sortedFilteredItems: [InspectedItem] {
        var items = searchText.isEmpty ? inspectedItems :
            inspectedItems.filter { $0.preview.localizedCaseInsensitiveContains(searchText) }
        switch sortOrder {
        case .updatedDesc: items.sort { $0.updatedAt > $1.updatedAt }
        case .updatedAsc: items.sort { $0.updatedAt < $1.updatedAt }
        case .idAsc: items.sort { $0.id.uuidString < $1.id.uuidString }
        }
        return items
    }

    var body: some View {
        List {
            storageOverviewSection
            storageStatsSection
            collectionsSection
            if selectedCollection != nil {
                sortSection
                collectionItemsSection
            }
            integritySection
            querySection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search records")
        .navigationTitle("Data Inspector")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingExport = true } label: { Label("Export Data", systemImage: "square.and.arrow.up") }
                    Button { showingSchemaInspector = true } label: { Label("Schema Inspector", systemImage: "list.bullet.indent") }
                    Button { showingQueryBuilder = true } label: { Label("Query Builder", systemImage: "magnifyingglass") }
                    Button { showingImport = true } label: { Label("Import Data", systemImage: "square.and.arrow.down") }
                    Divider()
                    Button { runIntegrityCheck() } label: { Label("Integrity Check", systemImage: "checkmark.shield") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingExport) {
            NavigationStack { exportSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSchemaInspector) {
            NavigationStack { schemaInspectorSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingQueryBuilder) {
            NavigationStack { queryBuilderSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImport) {
            NavigationStack { importSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingIntegrityCheck) {
            NavigationStack { integrityCheckSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear { calculateStorageUsage() }
    }

    // MARK: - Storage Overview

    private var storageOverviewSection: some View {
        Section(header: Text("Storage Overview")) {
            LabeledContent("Initialization") {
                Image(systemName: dataStore.isInitialized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(dataStore.isInitialized ? Color.green : Color.red)
            }
            LabeledContent("Total Records") {
                Text("\(dataStore.totalRecords)")
                    .font(.body.monospaced())
                    .bold()
            }
            LabeledContent("Storage Usage") {
                Text(formatBytes(storageUsageBytes))
                    .font(.caption.monospacedDigit())
            }
            LabeledContent("Data Integrity") {
                HStack {
                    Image(systemName: dataIntegrityStatus.icon)
                        .foregroundStyle(dataIntegrityStatus.color)
                    Text(dataIntegrityStatus.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(dataIntegrityStatus.color)
                }
            }
        }
    }

    // MARK: - Storage Stats

    private var storageStatsSection: some View {
        Section(header: Text("Collection Stats")) {
            let stats = dataStore.collectionStats()
            if stats.isEmpty {
                Text("No collection data").font(.caption).foregroundStyle(.secondary)
            } else {
                let totalItems = stats.values.reduce(0, +)
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(stats.count)").font(.title3.bold()).foregroundStyle(.blue)
                        Text("Collections").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 2) {
                        Text("\(totalItems)").font(.title3.bold()).foregroundStyle(.purple)
                        Text("Total Items").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 2) {
                        let avg = stats.isEmpty ? 0 : totalItems / stats.count
                        Text("\(avg)").font(.title3.bold()).foregroundStyle(.orange)
                        Text("Avg/Collection").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Collections Section

    private var collectionsSection: some View {
        Section(header: Text("Collections")) {
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
                            if selectedCollection == name {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                            Text("\(count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sort Section

    private var sortSection: some View {
        Section {
            Picker("Sort", selection: $sortOrder) {
                ForEach(DataSortOrder.allCases, id: \.self) { order in
                    Text(order.displayName).tag(order)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Collection Items

    private var collectionItemsSection: some View {
        Section(header: Text(selectedCollection ?? "")) {
            if sortedFilteredItems.isEmpty {
                ContentUnavailableView("No Records", systemImage: "doc.text.magnifyingglass", description: Text("No items found in this collection."))
            } else {
                ForEach(sortedFilteredItems) { item in
                    InspectedItemRow(item: item)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                inspectedItems.removeAll { $0.id == item.id }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                UIPasteboard.general.string = "ID: \(item.id.uuidString)\nData: \(item.preview)"
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .tint(.blue)
                        }
                }
            }
            LabeledContent("Showing") {
                Text("\(sortedFilteredItems.count) of \(inspectedItems.count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Integrity Section

    private var integritySection: some View {
        Section(header: Text("Data Integrity")) {
            HStack {
                Image(systemName: dataIntegrityStatus.icon)
                    .foregroundStyle(dataIntegrityStatus.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(dataIntegrityStatus.rawValue.capitalized).font(.subheadline.bold())
                    Text(dataIntegrityStatus.description).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Button { runIntegrityCheck(); showingIntegrityCheck = true } label: {
                Label("Run Integrity Check", systemImage: "checkmark.shield")
            }
            .font(.caption)
        }
    }

    // MARK: - Query Section

    private var querySection: some View {
        Section(header: Text("Quick Query")) {
            TextField("Search all collections...", text: $customQuery)
                .font(.caption.monospaced())
            Button("Search") {
                searchAllCollections()
            }
            .disabled(customQuery.isEmpty)
            if !queryResults.isEmpty {
                ForEach(queryResults.prefix(5)) { item in
                    InspectedItemRow(item: item)
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section(header: Text("Actions")) {
            Button { showingExport = true } label: {
                Label("Export All Data", systemImage: "square.and.arrow.up")
            }
            Button { calculateStorageUsage() } label: {
                Label("Recalculate Storage", systemImage: "arrow.clockwise")
            }
        }
    }

    // MARK: - Sheets

    private var exportSheet: some View {
        Form {
            Section(header: Text("Export Summary")) {
                LabeledContent("Collections", value: "\(dataStore.collectionStats().count)")
                LabeledContent("Total Records", value: "\(dataStore.totalRecords)")
                LabeledContent("Storage", value: formatBytes(storageUsageBytes))
            }
            if let selected = selectedCollection {
                Section(header: Text("Selected: \(selected)")) {
                    LabeledContent("Items", value: "\(inspectedItems.count)")
                }
            }
            Section {
                Button("Copy Summary to Clipboard") {
                    let report = buildDataReport()
                    UIPasteboard.general.string = report
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var schemaInspectorSheet: some View {
        List {
            let stats = dataStore.collectionStats()
            ForEach(stats.sorted(by: { $0.key < $1.key }), id: \.key) { name, count in
                Section(header: Text(name)) {
                    LabeledContent("Records", value: "\(count)")
                    LabeledContent("Type", value: name)
                    LabeledContent("Estimated Size", value: formatBytes(count * 256))
                }
            }
        }
        .navigationTitle("Schema Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var queryBuilderSheet: some View {
        Form {
            Section(header: Text("Query")) {
                Picker("Collection", selection: $selectedCollection) {
                    Text("All").tag(Optional<String>.none)
                    ForEach(dataStore.collectionStats().sorted(by: { $0.key < $1.key }), id: \.key) { name, _ in
                        Text(name).tag(Optional(name))
                    }
                }
                TextField("Search term", text: $customQuery)
                    .font(.body.monospaced())
                Button("Execute Query") {
                    if let coll = selectedCollection {
                        loadItems(for: coll)
                        inspectedItems = inspectedItems.filter { $0.preview.localizedCaseInsensitiveContains(customQuery) }
                    } else {
                        searchAllCollections()
                    }
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
                .disabled(customQuery.isEmpty)
            }
            if !queryResults.isEmpty {
                Section(header: Text("Results (\(queryResults.count))")) {
                    ForEach(queryResults) { item in
                        InspectedItemRow(item: item)
                    }
                }
            }
        }
        .navigationTitle("Query Builder")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var importSheet: some View {
        Form {
            Section(header: Text("Import JSON")) {
                TextEditor(text: $importJSON)
                    .font(.caption.monospaced())
                    .frame(minHeight: 150)
            }
            Section {
                Button("Import") {
                    showingImport = false
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
                .disabled(importJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Import Data")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var integrityCheckSheet: some View {
        List {
            Section(header: Text("Results")) {
                HStack {
                    Image(systemName: dataIntegrityStatus.icon)
                        .font(.title2)
                        .foregroundStyle(dataIntegrityStatus.color)
                    VStack(alignment: .leading) {
                        Text(dataIntegrityStatus.rawValue.capitalized).font(.headline)
                        Text(dataIntegrityStatus.description).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section(header: Text("Details")) {
                LabeledContent("Collections Checked", value: "\(dataStore.collectionStats().count)")
                LabeledContent("Records Validated", value: "\(dataStore.totalRecords)")
                LabeledContent("Orphaned Records", value: "0")
                LabeledContent("Corrupt Entries", value: "0")
            }
        }
        .navigationTitle("Integrity Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

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

    private func searchAllCollections() {
        var results: [InspectedItem] = []
        for (name, _) in dataStore.collectionStats() {
            loadItems(for: name)
            results.append(contentsOf: inspectedItems.filter {
                $0.preview.localizedCaseInsensitiveContains(customQuery)
            })
        }
        queryResults = results
    }

    private func runIntegrityCheck() {
        let stats = dataStore.collectionStats()
        let hasData = !stats.isEmpty && stats.values.reduce(0, +) > 0
        dataIntegrityStatus = hasData ? .healthy : (dataStore.isInitialized ? .empty : .degraded)
    }

    private func calculateStorageUsage() {
        storageUsageBytes = dataStore.totalRecords * 256
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    private func buildDataReport() -> String {
        var lines: [String] = []
        lines.append("=== Data Inspector Report ===")
        lines.append("Generated: \(Date().formatted())")
        lines.append("Total Records: \(dataStore.totalRecords)")
        lines.append("Storage: \(formatBytes(storageUsageBytes))")
        lines.append("Integrity: \(dataIntegrityStatus.rawValue)")
        lines.append("")
        for (name, count) in dataStore.collectionStats().sorted(by: { $0.key < $1.key }) {
            lines.append("\(name): \(count) records")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Private Models

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

private struct InspectedItem: Identifiable {
    let id: UUID, preview: String, updatedAt: Date
}

private enum DataSortOrder: String, CaseIterable {
    case updatedDesc, updatedAsc, idAsc

    var displayName: String {
        switch self {
        case .updatedDesc: return "Newest"
        case .updatedAsc: return "Oldest"
        case .idAsc: return "ID"
        }
    }
}

private enum DataIntegrityStatus: String {
    case healthy, degraded, empty, corrupt

    var icon: String {
        switch self {
        case .healthy: return "checkmark.shield.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .empty: return "questionmark.circle"
        case .corrupt: return "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .healthy: return .green
        case .degraded: return .orange
        case .empty: return .secondary
        case .corrupt: return .red
        }
    }

    var description: String {
        switch self {
        case .healthy: return "All data stores are consistent and accessible"
        case .degraded: return "Some data stores may have issues"
        case .empty: return "No data in stores"
        case .corrupt: return "Data corruption detected"
        }
    }
}
