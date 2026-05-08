import SwiftUI

struct ConnectorVersioningView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared
    @State private var newVersion = ""
    @State private var releaseNotes = ""
    @State private var showingReleaseSheet = false
    @State private var showingRollbackAlert = false
    @State private var rollbackTarget = ""
    @State private var showingCompare = false
    @State private var deploymentStatus: DeploymentStatus = .deployed

    enum DeploymentStatus: String, CaseIterable {
        case deployed = "Deployed"
        case staging = "Staging"
        case rollback = "Rolled Back"
        case draft = "Draft"
    }

    struct VersionEntry: Identifiable {
        let id = UUID()
        let version: String
        let date: Date
        let notes: String
        let status: DeploymentStatus
        let changes: Int
    }

    var versionHistory: [VersionEntry] {
        [VersionEntry(version: connector.version, date: connector.updatedAt, notes: "Current saved connector configuration", status: deploymentStatus, changes: connector.endpoints.count + connector.flow.steps.count + connector.schema.mappings.count)]
    }

    private var connectorLogs: [ConnectorLog] {
        manager.logs.filter { $0.connectorID == connector.id }
    }

    var body: some View {
        List {
            // MARK: - Version Overview
            Section {
                HStack(spacing: 16) {
                    versionStat(label: "Current", value: "v\(connector.version)", color: .blue)
                    versionStat(label: "Releases", value: "\(versionHistory.count)", color: .purple)
                    versionStat(label: "Status", value: deploymentStatus.rawValue, color: deploymentStatus == .deployed ? .green : .orange)
                }
            }

            // MARK: - Active Version
            Section {
                HStack {
                    Text("Current Version")
                    Spacer()
                    Text("v\(connector.version)")
                        .bold()
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                HStack {
                    Text("Last Updated")
                    Spacer()
                    Text(connector.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Deployment Status")
                    Spacer()
                    Picker("Status", selection: $deploymentStatus) {
                        ForEach(DeploymentStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                }
                HStack {
                    Text("Created")
                    Spacer()
                    Text(connector.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Endpoints")
                    Spacer()
                    Text("\(connector.endpoints.count)")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Flow Steps")
                    Spacer()
                    Text("\(connector.flow.steps.count)")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Active Version")
            }

            // MARK: - Version History
            Section {
                if versionHistory.count == 1 {
                    Text("Only the current saved version is available. No generated or mock versions are shown.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(versionHistory) { entry in
                    historyRow(entry: entry)
                        .contextMenu {
                            if entry.version != connector.version {
                                Button {
                                    rollbackTarget = entry.version
                                    showingRollbackAlert = true
                                } label: {
                                    Label("Rollback to v\(entry.version)", systemImage: "arrow.uturn.backward")
                                }
                            }

                            Button {
                                showingCompare = true
                            } label: {
                                Label("Compare Versions", systemImage: "arrow.left.arrow.right")
                            }

                            Button {
                                UIPasteboard.general.string = "v\(entry.version) - \(entry.notes)"
                            } label: {
                                Label("Copy Version Info", systemImage: "doc.on.doc")
                            }
                        }
                }
            } header: {
                Text("Version History")
            }

            // MARK: - Changelog
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    changelogEntry(type: "Current", items: configurationChangeItems)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Configuration Changelog")
            }

            if !connectorLogs.isEmpty {
                Section {
                    ForEach(connectorLogs.prefix(5)) { log in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(log.message).font(.caption)
                            Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("User Activity")
                }
            }

            // MARK: - Actions
            Section {
                Button {
                    newVersion = incrementVersion(connector.version)
                    showingReleaseSheet = true
                } label: {
                    Label("Create New Release", systemImage: "arrow.up.circle.fill")
                }

                if versionHistory.count > 1 {
                    Button {
                        rollbackTarget = versionHistory[1].version
                        showingRollbackAlert = true
                    } label: {
                        Label("Rollback to Previous Version", systemImage: "arrow.uturn.backward")
                    }
                }

                Button {
                    showingCompare = true
                } label: {
                    Label("Compare Versions", systemImage: "arrow.left.arrow.right")
                }
            }
        }
        .navigationTitle("Versioning")
        .sheet(isPresented: $showingReleaseSheet) {
            releaseSheet
        }
        .sheet(isPresented: $showingCompare) {
            compareSheet
        }
        .alert("Rollback to v\(rollbackTarget)?", isPresented: $showingRollbackAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Rollback", role: .destructive) {
                connector.version = rollbackTarget
                connector.updatedAt = Date()
                deploymentStatus = .rollback
                manager.updateConnector(connector)
                manager.addLog(ConnectorLog(connectorID: connector.id, timestamp: Date(), type: .warning, message: "Rolled back to v\(rollbackTarget)", details: nil))
            }
        } message: {
            Text("This will revert the connector to version \(rollbackTarget). Current configuration will be preserved as a snapshot.")
        }
    }

    // MARK: - Release Sheet

    private var releaseSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextField("New Version (e.g. 1.1.0)", text: $newVersion)
                        .font(.system(.body, design: .monospaced))

                    VStack(alignment: .leading) {
                        Text("Release Notes").font(.caption).foregroundColor(.secondary)
                        TextEditor(text: $releaseNotes)
                            .frame(minHeight: 120)
                    }
                } header: {
                    Text("Release Details")
                }

                Section {
                    LabeledContent("From Version", value: "v\(connector.version)")
                    LabeledContent("To Version", value: newVersion.isEmpty ? "-" : "v\(newVersion)")
                    LabeledContent("Endpoints", value: "\(connector.endpoints.count)")
                    LabeledContent("Flow Steps", value: "\(connector.flow.steps.count)")
                } header: {
                    Text("Release Summary")
                }

                Section {
                    HStack {
                        Image(systemName: connector.endpoints.isEmpty ? "xmark.circle" : "checkmark.circle.fill")
                            .foregroundColor(connector.endpoints.isEmpty ? .red : .green)
                        Text("Endpoints Configured")
                    }
                    HStack {
                        Image(systemName: connector.authConfig.type == .none ? "xmark.circle" : "checkmark.circle.fill")
                            .foregroundColor(connector.authConfig.type == .none ? .orange : .green)
                        Text("Authentication Configured")
                    }
                    HStack {
                        Image(systemName: connector.flow.steps.isEmpty ? "xmark.circle" : "checkmark.circle.fill")
                            .foregroundColor(connector.flow.steps.isEmpty ? .orange : .green)
                        Text("Flow Pipeline Defined")
                    }
                } header: {
                    Text("Pre Release Checklist")
                }

                Section {
                    Button("Publish Release") {
                        connector.version = newVersion
                        connector.updatedAt = Date()
                        deploymentStatus = .deployed
                        manager.updateConnector(connector)
                        manager.addLog(ConnectorLog(connectorID: connector.id, timestamp: Date(), type: .info, message: "Published version v\(connector.version)", details: releaseNotes.isEmpty ? nil : releaseNotes))
                        showingReleaseSheet = false
                        releaseNotes = ""
                    }
                    .frame(maxWidth: .infinity)
                    .bold()
                    .disabled(newVersion == connector.version || newVersion.isEmpty)
                }
            }
            .navigationTitle("New Release")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingReleaseSheet = false }
                }
            }
        }
    }

    // MARK: - Compare Sheet

    private var compareSheet: some View {
        NavigationView {
            List {
                Section {
                    if versionHistory.count >= 2 {
                        let current = versionHistory[0]
                        let previous = versionHistory[1]

                        HStack {
                            VStack {
                                Text("v\(previous.version)")
                                    .font(.headline)
                                Text("Previous")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)

                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)

                            VStack {
                                Text("v\(current.version)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Text("Current")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                } header: {
                    Text("Version Comparison")
                }

                Section {
                    LabeledContent("Endpoints", value: "\(connector.endpoints.count)")
                    LabeledContent("Flow Steps", value: "\(connector.flow.steps.count)")
                    LabeledContent("Auth Type", value: connector.authConfig.type.rawValue.capitalized)
                    LabeledContent("Schema Mappings", value: "\(connector.schema.mappings.count)")
                } header: {
                    Text("Configuration Diff")
                }

                Section {
                    ForEach(versionHistory) { entry in
                        HStack {
                            Circle()
                                .fill(entry.status == .deployed ? Color.green : Color.secondary)
                                .frame(width: 8, height: 8)
                            Text("v\(entry.version)")
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Timeline")
                }
            }
            .navigationTitle("Compare Versions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingCompare = false }
                }
            }
        }
    }

    private var configurationChangeItems: [String] {
        var items = [
            "\(connector.endpoints.count) endpoint(s) configured",
            "\(connector.flow.steps.count) flow step(s) configured",
            "Auth type: \(connector.authConfig.type.rawValue.capitalized)",
            "\(connector.schema.mappings.count) schema mapping(s)"
        ]
        if let lastLog = connectorLogs.first {
            items.append("Latest user activity: \(lastLog.message)")
        }
        return items
    }

    // MARK: - Subviews

    private func historyRow(entry: VersionEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(entry.status == .deployed ? Color.green : Color.blue)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 2, height: 30)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("v\(entry.version)")
                        .font(.subheadline.bold())

                    Text(entry.status.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(entry.status).opacity(0.15))
                        .foregroundColor(statusColor(entry.status))
                        .clipShape(Capsule())

                    Spacer()

                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(entry.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func changelogEntry(type: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(type)
                .font(.caption.bold())
                .foregroundColor(changelogColor(type))

            ForEach(items, id: \.self) { item in
                HStack(spacing: 6) {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func versionStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func statusColor(_ status: DeploymentStatus) -> Color {
        switch status {
        case .deployed: return .green
        case .staging: return .orange
        case .rollback: return .red
        case .draft: return .secondary
        }
    }

    private func changelogColor(_ type: String) -> Color {
        switch type {
        case "Added": return .green
        case "Changed": return .blue
        case "Fixed": return .orange
        case "Removed": return .red
        default: return .secondary
        }
    }

    private func incrementVersion(_ version: String) -> String {
        let parts = version.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 3 else { return version }
        return "\(parts[0]).\(parts[1]).\(parts[2] + 1)"
    }

}
