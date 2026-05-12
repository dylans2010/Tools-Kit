

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

    enum DeploymentStatus: String, CaseIterable, Sendable { case deployed = "Deployed", staging = "Staging", rollback = "Rolled Back", draft = "Draft" }

    struct VersionEntry: Identifiable, Sendable {
        let id = UUID(); let version: String; let date: Date; let notes: String; let status: DeploymentStatus; let changes: Int
    }

    var versionHistory: [VersionEntry] {
        [VersionEntry(version: connector.version, date: connector.updatedAt, notes: "Current saved connector configuration", status: deploymentStatus, changes: connector.endpoints.count + connector.flow.steps.count + connector.schema.mappings.count)]
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 0) {
                    DetailMetricPill(label: "Version", value: "v\(connector.version)", color: .blue)
                    DetailMetricPill(label: "History", value: "\(versionHistory.count)", color: .purple)
                    DetailMetricPill(label: "Status", value: deploymentStatus.rawValue, color: deploymentStatus == .deployed ? .sdkSuccess : .orange)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear).listRowInsets(EdgeInsets())

            CurrentReleaseSection(connector: connector, status: $deploymentStatus)

            Section("Version History") {
                if versionHistory.count == 1 { Text("Only the current saved version is available.").font(.caption).foregroundStyle(.secondary) }
                ForEach(versionHistory) { entry in
                    VersionHistoryRow(entry: entry, isCurrent: entry.version == connector.version, onRollback: { rollbackTarget = $0; showingRollbackAlert = true })
                }
            }

            Section("Configuration Diff") {
                VStack(alignment: .leading, spacing: 8) {
                    DiffItem(label: "Endpoints", value: "\(connector.endpoints.count)")
                    DiffItem(label: "Flow Steps", value: "\(connector.flow.steps.count)")
                    DiffItem(label: "Auth Type", value: connector.authConfig.type.rawValue.capitalized)
                }.padding(.vertical, 4)
            }

            Section {
                Button(action: { newVersion = incrementVersion(connector.version); showingReleaseSheet = true }) { Label("Create New Release", systemImage: "arrow.up.circle.fill").font(.subheadline.bold()) }
                Button(action: { showingCompare = true }) { Label("Compare Changes", systemImage: "arrow.left.arrow.right") }
            }
        }
        .listStyle(.insetGrouped).navigationTitle("Versioning").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReleaseSheet) { ReleaseManagementSheet(connector: connector, newVersion: $newVersion, notes: $releaseNotes, onPublish: { connector.version = newVersion; deploymentStatus = .deployed; manager.updateConnector(connector); showingReleaseSheet = false }).presentationDetents([.large]) }
        .sheet(isPresented: $showingCompare) { CompareVersionsSheet(history: versionHistory).presentationDetents([.large]) }
        .alert("Rollback to v\(rollbackTarget)?", isPresented: $showingRollbackAlert) { Button("Cancel", role: .cancel) {}; Button("Rollback", role: .destructive) { connector.version = rollbackTarget; deploymentStatus = .rollback; manager.updateConnector(connector) } } message: { Text("This will revert the active configuration.") }
    }

    private func incrementVersion(_ v: String) -> String { let p = v.split(separator: ".").compactMap { Int($0) }; return p.count == 3 ? "\(p[0]).\(p[1]).\(p[2] + 1)" : v }
}

// MARK: - Private Subviews

private struct CurrentReleaseSection: View {
    let connector: ConnectorDefinition
    @Binding var status: ConnectorVersioningView.DeploymentStatus
    var body: some View {
        Section("Active Deployment") {
            LabeledContent("Live Version") { Text("v\(connector.version)").bold().foregroundStyle(.blue) }
            LabeledContent("Last Updated", value: connector.updatedAt.formatted(.relative(presentation: .named)))
            Picker("Environment", selection: $status) { ForEach(ConnectorVersioningView.DeploymentStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu)
            LabeledContent("Auth Method", value: connector.authConfig.type.rawValue.capitalized)
        }
    }
}

private struct VersionHistoryRow: View {
    let entry: ConnectorVersioningView.VersionEntry; let isCurrent: Bool; let onRollback: (String) -> Void
    var body: some View {
        HStack(spacing: 12) {
            VStack { Circle().fill(isCurrent ? .green : .blue).frame(width: 8, height: 8); Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 2) }
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text("v\(entry.version)").font(.subheadline.bold()); Spacer(); Text(entry.date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.secondary) }
                Text(entry.notes).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .contextMenu { if !isCurrent { Button { onRollback(entry.version) } label: { Label("Rollback", systemImage: "arrow.uturn.backward") } }; Button { UIPasteboard.general.string = entry.version } label: { Label("Copy Version", systemImage: "doc.on.doc") } }
    }
}

private struct ReleaseManagementSheet: View {
    let connector: ConnectorDefinition; @Binding var newVersion: String; @Binding var notes: String; let onPublish: () -> Void; @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Release Identity") { TextField("Version", text: $newVersion).font(.caption.monospaced()); TextEditor(text: $notes).frame(minHeight: 100).font(.caption).padding(4).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8)) }
                Section("Checklist") {
                    ReleaseCheckItem(title: "Endpoints Configured", met: !connector.endpoints.isEmpty)
                    ReleaseCheckItem(title: "Auth Strategy Defined", met: connector.authConfig.type != .none)
                    ReleaseCheckItem(title: "Flow Sequence Valid", met: !connector.flow.steps.isEmpty)
                }
                Section { Button(action: onPublish) { Text("Publish v\(newVersion)").frame(maxWidth: .infinity).bold() }.buttonStyle(.borderedProminent).disabled(newVersion.isEmpty) }.listRowBackground(Color.clear)
            }
            .navigationTitle("New Release").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

private struct CompareVersionsSheet: View {
    let history: [ConnectorVersioningView.VersionEntry]; @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List { Section("Comparison Timeline") { ForEach(history) { entry in LabeledContent("v\(entry.version)", value: entry.date.formatted(date: .abbreviated, time: .omitted)) } } }
            .navigationTitle("Diff Viewer").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

private struct ReleaseCheckItem: View {
    let title: String; let met: Bool
    var body: some View { Label { Text(title).font(.subheadline) } icon: { Image(systemName: met ? "checkmark.circle.fill" : "circle").foregroundStyle(met ? Color.green : Color.secondary) } }
}

private struct DiffItem: View {
    let label: String; let value: String
    var body: some View { HStack { Text(label).font(.caption); Spacer(); Text(value).font(.caption2.monospaced()).foregroundStyle(.secondary) } }
}

private struct DetailMetricPill: View {
    let label: String; let value: String; let color: Color
    var body: some View { VStack(spacing: 4) { Text(value).font(.headline).foregroundStyle(color); Text(label).font(.caption2.bold()).foregroundStyle(.secondary) }.frame(maxWidth: .infinity) }
}
