/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Modernized the header stats using a centered StatHeader section with SDKStatPill.
 - Replaced manual project integration list with native LabeledContent rows.
 - Modernized the Activity section using monospaced timestamps and improved hierarchy.
 - Replaced manual connector rows with a dedicated SDKConnectorRow sub-struct.
 - strictly preserved all SDKConnectorManager, SDKProjectManager, and BaseConnector logic.
 - Standardized empty states using ContentUnavailableView.
 - Improved visual hierarchy for connection status (SDKStatusPill).
 - Extracted subviews for StatHeader, SDKConnectorRow, and empty states.
 */

import SwiftUI

struct SDKConnectorsView: View {
    @StateObject private var manager = SDKConnectorManager.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var filterStatus: FilterStatus = .all
    @State private var sortOrder: SortOrder = .name

    enum FilterStatus: String, CaseIterable {
        case all = "All"
        case connected = "Connected"
        case disconnected = "Disconnected"
    }

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case type = "Type"
        case status = "Status"
    }

    var filteredConnectors: [any BaseConnector] {
        var result = manager.connectors
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch filterStatus {
        case .all: break
        case .connected: result = result.filter { $0.status == .connected }
        case .disconnected: result = result.filter { $0.status != .connected }
        }
        switch sortOrder {
        case .name: result = result.sorted { $0.name < $1.name }
        case .type: result = result.sorted { $0.type.rawValue < $1.type.rawValue }
        case .status: result = result.sorted { $0.status.rawValue < $1.status.rawValue }
        }
        return result
    }

    var body: some View {
        List {
            if !manager.connectors.isEmpty {
                Section {
                    SDKConnectorsStatHeader(manager: manager)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

                Section("Project Integration") {
                    LabeledContent("Current Project", value: projectManager.currentProject?.name ?? "None")
                    LabeledContent("Active Links", value: "\(projectManager.currentProject?.enabledConnectorIDs.count ?? 0)")
                    LabeledContent("System Events", value: "\(logStore.entries.count)")
                }

                if let latestEvent = manager.connectors.flatMap({ $0.activityLog }).sorted(by: { $0.timestamp > $1.timestamp }).first {
                    Section("Latest Activity") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(latestEvent.message).font(.subheadline)
                            Text(latestEvent.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2.monospaced()).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Picker("Status", selection: $filterStatus) {
                        ForEach(FilterStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    Picker("Sort By", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
            }

            Section("Connectors") {
                if filteredConnectors.isEmpty {
                    ContentUnavailableView(
                        manager.connectors.isEmpty ? "No Connectors" : "No Results",
                        systemImage: "puzzlepiece.extension",
                        description: Text(manager.connectors.isEmpty ? "Register SDK connectors to integrate external modules." : "No modules match your current filter.")
                    )
                } else {
                    ForEach(filteredConnectors, id: \.id) { connector in
                        NavigationLink(value: connector.id) {
                            SDKConnectorRow(connector: connector)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { manager.remove(id: connector.id) } label: { Label("Remove", systemImage: "trash") }
                        }
                    }
                }
            }

            if !manager.connectors.isEmpty {
                Section("Global Controls") {
                    Button {
                        Task { for c in manager.connectors { try? await c.testConnection() } }
                    } label: {
                        Label("Test All Connections", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    Button {
                        Task { for c in manager.connectors { try? await c.sync() } }
                    } label: {
                        Label("Sync All Connectors", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search modules...")
        .navigationTitle("SDK Connectors")
        .navigationDestination(for: UUID.self) { id in
            if let connector = manager.connectors.first(where: { $0.id == id }) as? GmailConnector { ConnectorDetailView(connector: connector) }
            else if let connector = manager.connectors.first(where: { $0.id == id }) as? GitHubConnector { ConnectorDetailView(connector: connector) }
            else if let connector = manager.connectors.first(where: { $0.id == id }) as? WebhookConnector { ConnectorDetailView(connector: connector) }
            else if let connector = manager.connectors.first(where: { $0.id == id }) as? CalendarConnector { ConnectorDetailView(connector: connector) }
            else if let connector = manager.connectors.first(where: { $0.id == id }) as? LocalFileConnector { ConnectorDetailView(connector: connector) }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSheet = true } label: { Label("Add", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ConnectorBuilderView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }
}

// MARK: - Private Subviews

private struct SDKConnectorsStatHeader: View {
    @ObservedObject var manager: SDKConnectorManager
    var body: some View {
        let total = manager.connectors.count
        let connected = manager.connectors.filter { $0.status == .connected }.count
        return HStack(spacing: 0) {
            SDKStatPill(label: "Total", value: "\(total)", color: .blue)
            SDKStatPill(label: "Live", value: "\(connected)", color: .sdkSuccess)
            SDKStatPill(label: "Offline", value: "\(total - connected)", color: .secondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }
}

private struct SDKConnectorRow: View {
    let connector: any BaseConnector
    @StateObject private var projectManager = SDKProjectManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: connector.type))
                .font(.headline).foregroundStyle(connector.status == .connected ? Color.accentColor : .secondary)
                .frame(width: 32, height: 32).background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(connector.name).font(.subheadline.bold())
                HStack(spacing: 4) {
                    Text(connector.type.rawValue.capitalized).font(.caption2)
                    if let current = projectManager.currentProject, current.enabledConnectorIDs.contains(connector.id) {
                        Text("·").font(.caption2).foregroundStyle(.tertiary)
                        Text("Project Enabled").font(.caption2).foregroundStyle(.sdkSuccess)
                    }
                }.foregroundStyle(.secondary)
            }
            Spacer()
            SDKStatusPill(
                connector.status.rawValue.uppercased(),
                systemImage: connector.status == .connected ? "checkmark.circle.fill" : "xmark.circle.fill",
                color: connector.status == .connected ? .sdkSuccess : .secondary
            )
        }
        .padding(.vertical, 2)
    }

    private func icon(for type: ConnectorType) -> String {
        switch type {
        case .gmail: return "envelope.fill"
        case .webhook: return "network"
        case .github: return "terminal.fill"
        case .localFileSystem: return "folder.fill"
        case .calendar: return "calendar"
        }
    }
}
