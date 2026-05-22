import SwiftUI

struct ConnectorTemplatesView: View {
    @State private var templates: [ConnectorTemplateItem] = []
    @State private var searchText = ""
    @State private var selectedCategory: ConnectorCategory?
    @State private var showingTemplateDetail = false
    @State private var selectedTemplate: ConnectorTemplateItem?
    @State private var showingCustomBuilder = false
    @State private var sortOrder: TemplateSortOrder = .name
    @State private var showingImport = false
    @State private var importJSON = ""
    @State private var favoriteIDs: Set<UUID> = []
    @State private var recentlyUsedIDs: [UUID] = []
    @State private var showingExport = false
    @State private var filterComplexity: Complexity?

    fileprivate var filteredTemplates: [ConnectorTemplateItem] {
        var result = templates
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if let complexity = filterComplexity {
            result = result.filter { $0.complexity == complexity }
        }
        switch sortOrder {
        case .name: result.sort { $0.name < $1.name }
        case .complexity: result.sort { $0.complexity.sortOrder < $1.complexity.sortOrder }
        case .category: result.sort { $0.category.rawValue < $1.category.rawValue }
        case .favorites: result.sort { favoriteIDs.contains($0.id) && !favoriteIDs.contains($1.id) }
        }
        return result
    }

    private var favoritedTemplates: [ConnectorTemplateItem] {
        templates.filter { favoriteIDs.contains($0.id) }
    }

    private var recentTemplates: [ConnectorTemplateItem] {
        recentlyUsedIDs.compactMap { id in templates.first(where: { $0.id == id }) }
    }

    var body: some View {
        List {
            overviewSection
            if !recentTemplates.isEmpty { recentSection }
            if !favoritedTemplates.isEmpty { favoritesSection }
            categoryFilterSection
            complexityFilterSection
            sortSection
            templatesListSection
        }
        .navigationTitle("Connector Templates")
        .searchable(text: $searchText, prompt: "Search templates")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingCustomBuilder = true } label: { Label("Create Custom", systemImage: "plus.rectangle") }
                    Button { showingImport = true } label: { Label("Import Template", systemImage: "square.and.arrow.down") }
                    Button { showingExport = true } label: { Label("Export All", systemImage: "square.and.arrow.up") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .task { loadTemplates() }
        .sheet(item: $selectedTemplate) { template in
            NavigationStack { templateDetailSheet(template) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingCustomBuilder) {
            NavigationStack { customTemplateBuilder }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImport) {
            NavigationStack { importTemplateSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExport) {
            NavigationStack { exportTemplatesSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        Section("Template Library") {
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(templates.count)").font(.title3.bold()).foregroundStyle(.blue)
                    Text("Templates").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(ConnectorCategory.allCases.count)").font(.title3.bold()).foregroundStyle(.purple)
                    Text("Categories").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(favoriteIDs.count)").font(.title3.bold()).foregroundStyle(.orange)
                    Text("Favorites").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        Section("Recently Used") {
            ForEach(recentTemplates.prefix(3)) { template in
                templateCompactRow(template)
            }
        }
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        Section("Favorites") {
            ForEach(favoritedTemplates) { template in
                templateCompactRow(template)
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilterSection: some View {
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
    }

    // MARK: - Complexity Filter

    private var complexityFilterSection: some View {
        Section("Difficulty") {
            HStack {
                complexityButton(nil, label: "Any")
                complexityButton(.simple, label: "Simple")
                complexityButton(.medium, label: "Medium")
                complexityButton(.advanced, label: "Advanced")
            }
        }
    }

    // MARK: - Sort

    private var sortSection: some View {
        Section {
            Picker("Sort By", selection: $sortOrder) {
                ForEach(TemplateSortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue.capitalized).tag(order)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Templates List

    private var templatesListSection: some View {
        Section("Templates (\(filteredTemplates.count))") {
            if filteredTemplates.isEmpty {
                ContentUnavailableView("No Templates Found", systemImage: "doc.text.magnifyingglass", description: Text("Adjust your filters or search to find templates."))
            } else {
                ForEach(filteredTemplates) { template in
                    Button { selectedTemplate = template } label: {
                        HStack(spacing: 12) {
                            Image(systemName: template.icon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(template.category.color.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(template.name)
                                        .font(.headline)
                                    if favoriteIDs.contains(template.id) {
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.yellow)
                                    }
                                }
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                HStack {
                                    Label(template.category.rawValue.capitalized, systemImage: "tag")
                                    Label(template.complexity.rawValue.capitalized, systemImage: "gauge.medium")
                                    if template.endpointCount > 0 {
                                        Label("\(template.endpointCount) endpoints", systemImage: "point.3.connected.trianglepath.dotted")
                                    }
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .leading) {
                        Button {
                            if favoriteIDs.contains(template.id) { favoriteIDs.remove(template.id) }
                            else { favoriteIDs.insert(template.id) }
                        } label: {
                            Label(favoriteIDs.contains(template.id) ? "Unfavorite" : "Favorite", systemImage: "star")
                        }
                        .tint(.yellow)
                    }
                }
            }
        }
    }

    // MARK: - Sheets

    private func templateDetailSheet(_ template: ConnectorTemplateItem) -> some View {
        Form {
            Section {
                HStack {
                    Image(systemName: template.icon)
                        .font(.largeTitle)
                        .foregroundStyle(template.category.color)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name).font(.title3.bold())
                        Text(template.description).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Details") {
                LabeledContent("Category", value: template.category.rawValue.capitalized)
                LabeledContent("Complexity", value: template.complexity.rawValue.capitalized)
                LabeledContent("Endpoints", value: "\(template.endpointCount)")
                LabeledContent("Auth Type", value: template.authType)
                LabeledContent("Rate Limit", value: template.rateLimit)
            }

            if !template.features.isEmpty {
                Section("Features") {
                    ForEach(template.features, id: \.self) { feature in
                        Label(feature, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Section {
                NavigationLink(destination: ConnectorBuilderView()) {
                    Label("Use This Template", systemImage: "hammer")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)

                Button {
                    recentlyUsedIDs.insert(template.id, at: 0)
                    if recentlyUsedIDs.count > 5 { recentlyUsedIDs = Array(recentlyUsedIDs.prefix(5)) }
                } label: {
                    Label("Add to Recent", systemImage: "clock")
                        .frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var customTemplateBuilder: some View {
        Form {
            Section("Template Details") {
                TextField("Name", text: .constant(""))
                TextField("Description", text: .constant(""))
                Picker("Category", selection: .constant(ConnectorCategory.api)) {
                    ForEach(ConnectorCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue.capitalized).tag(cat)
                    }
                }
                Picker("Complexity", selection: .constant(Complexity.simple)) {
                    ForEach([Complexity.simple, .medium, .advanced], id: \.self) { c in
                        Text(c.rawValue.capitalized).tag(c)
                    }
                }
            }
        }
        .navigationTitle("Custom Template")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var importTemplateSheet: some View {
        Form {
            Section("Import JSON") {
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
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Import Template")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var exportTemplatesSheet: some View {
        Form {
            Section("Export") {
                Text("\(templates.count) templates will be exported")
                    .font(.caption)
                Button("Copy to Clipboard") {
                    let names = templates.map { $0.name }
                    UIPasteboard.general.string = names.joined(separator: "\n")
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Export Templates")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func templateCompactRow(_ template: ConnectorTemplateItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: template.icon)
                .foregroundStyle(template.category.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(template.name).font(.subheadline)
                Text(template.category.rawValue.capitalized).font(.caption2).foregroundStyle(.secondary)
            }
        }
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

    private func complexityButton(_ complexity: Complexity?, label: String) -> some View {
        Button {
            filterComplexity = complexity
        } label: {
            Text(label)
                .font(.caption2)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(filterComplexity == complexity ? Color.purple : Color(.secondarySystemBackground))
                .foregroundStyle(filterComplexity == complexity ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func loadTemplates() {
        templates = [
            ConnectorTemplateItem(name: "REST API Gateway", description: "Full REST API connector with CRUD endpoints, pagination, and error handling", icon: "network", category: .api, complexity: .medium, endpointCount: 8, authType: "Bearer Token", rateLimit: "100/min", features: ["GET/POST/PUT/DELETE", "Pagination support", "Rate limiting", "Error retry"]),
            ConnectorTemplateItem(name: "GraphQL Client", description: "GraphQL query and mutation connector with schema introspection", icon: "point.3.connected.trianglepath.dotted", category: .api, complexity: .advanced, endpointCount: 3, authType: "Bearer Token", rateLimit: "50/min", features: ["Query execution", "Mutations", "Subscriptions", "Schema introspection"]),
            ConnectorTemplateItem(name: "WebSocket Stream", description: "Real-time bidirectional WebSocket communication connector", icon: "antenna.radiowaves.left.and.right", category: .events, complexity: .advanced, endpointCount: 2, authType: "API Key", rateLimit: "Unlimited", features: ["Bidirectional messaging", "Auto-reconnect", "Heartbeat monitoring", "Message queuing"]),
            ConnectorTemplateItem(name: "Webhook Receiver", description: "Incoming webhook handler with signature verification", icon: "bolt.fill", category: .events, complexity: .simple, endpointCount: 1, authType: "HMAC-SHA256", rateLimit: "500/min", features: ["Signature verification", "Payload parsing", "Event routing"]),
            ConnectorTemplateItem(name: "Database Bridge", description: "Direct database connector supporting SQL and NoSQL", icon: "cylinder", category: .data, complexity: .advanced, endpointCount: 6, authType: "Connection String", rateLimit: "200/min", features: ["SQL queries", "Connection pooling", "Transaction support", "Schema migration"]),
            ConnectorTemplateItem(name: "S3 Storage", description: "AWS S3 compatible object storage connector", icon: "externaldrive.fill.badge.icloud", category: .storage, complexity: .medium, endpointCount: 5, authType: "AWS Signature V4", rateLimit: "100/min", features: ["Upload/Download", "Presigned URLs", "Bucket management", "Multipart upload"]),
            ConnectorTemplateItem(name: "Email SMTP", description: "Send emails via SMTP with template support", icon: "envelope.fill", category: .messaging, complexity: .medium, endpointCount: 3, authType: "SMTP Credentials", rateLimit: "30/min", features: ["HTML templates", "Attachments", "CC/BCC support", "Delivery tracking"]),
            ConnectorTemplateItem(name: "OAuth2 Provider", description: "Full OAuth2 authorization code flow with refresh tokens", icon: "lock.shield.fill", category: .auth, complexity: .advanced, endpointCount: 4, authType: "OAuth2", rateLimit: "20/min", features: ["Authorization code flow", "Token refresh", "Scope management", "PKCE support"]),
            ConnectorTemplateItem(name: "Slack Bot", description: "Slack workspace integration with message posting and slash commands", icon: "message.fill", category: .messaging, complexity: .medium, endpointCount: 5, authType: "Bot Token", rateLimit: "60/min", features: ["Post messages", "Slash commands", "Interactive components", "File uploads"]),
            ConnectorTemplateItem(name: "CSV Data Importer", description: "Bulk CSV file import with field mapping and validation", icon: "tablecells", category: .data, complexity: .simple, endpointCount: 2, authType: "None", rateLimit: "10/min", features: ["Field mapping", "Data validation", "Batch processing", "Error reporting"]),
            ConnectorTemplateItem(name: "MQTT Broker", description: "IoT message broker connector with topic subscription", icon: "sensor.fill", category: .events, complexity: .medium, endpointCount: 3, authType: "Username/Password", rateLimit: "1000/min", features: ["Publish/Subscribe", "QoS levels", "Retained messages", "Last will"]),
            ConnectorTemplateItem(name: "Redis Cache", description: "High-performance cache connector with TTL management", icon: "memorychip", category: .storage, complexity: .simple, endpointCount: 4, authType: "Password", rateLimit: "500/min", features: ["Get/Set/Delete", "TTL management", "Key patterns", "Pub/Sub"])
        ]
    }
}

// MARK: - Private Models

private struct ConnectorTemplateItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: ConnectorCategory
    let complexity: Complexity
    let endpointCount: Int
    let authType: String
    let rateLimit: String
    let features: [String]
}

private enum ConnectorCategory: String, CaseIterable {
    case api, events, data, storage, messaging, auth

    var color: Color {
        switch self {
        case .api: return .blue
        case .events: return .orange
        case .data: return .green
        case .storage: return .purple
        case .messaging: return .cyan
        case .auth: return .red
        }
    }
}

private enum Complexity: String, Hashable {
    case simple, medium, advanced

    var sortOrder: Int {
        switch self {
        case .simple: return 0
        case .medium: return 1
        case .advanced: return 2
        }
    }
}

private enum TemplateSortOrder: String, CaseIterable {
    case name, complexity, category, favorites
}
