

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

    enum DeploymentStatus: String, CaseIterable { case deployed = "Deployed", staging = "Staging", rollback = "Rolled Back", draft = "Draft" }

    struct VersionEntry: Identifiable {
        let id = UUID(); let version: String; let date: Date; let notes: String; let status: DeploymentStatus; let changes: Int
    }

    var versionHistory: [VersionEntry] {
        [VersionEntry(version: connector.version, date: connector.updatedAt, notes: "Current saved connector configuration", status: deploymentStatus, changes: connector.endpoints.count + connector.flow.steps.count + connector.schema.mappings.count)]
    }

    @State private var showingBranchManager = false
    @State private var branches: [VersionBranch] = [
        VersionBranch(name: "main", isDefault: true, lastActivity: Date()),
        VersionBranch(name: "staging", isDefault: false, lastActivity: Date().addingTimeInterval(-86400)),
        VersionBranch(name: "development", isDefault: false, lastActivity: Date().addingTimeInterval(-172800))
    ]
    @State private var selectedBranch = "main"
    @State private var showingMergeSheet = false
    @State private var enableAutoVersioning = false
    @State private var versioningStrategy: VersioningStrategy = .semantic
    @State private var showingTagManager = false
    @State private var tags: [VersionTag] = []
    @State private var newTagName = ""
    @State private var showingChangelogGenerator = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 0) {
                    DetailMetricPill(label: "Version", value: "v\(connector.version)", color: .blue)
                    DetailMetricPill(label: "History", value: "\(versionHistory.count)", color: .purple)
                    DetailMetricPill(label: "Status", value: deploymentStatus.rawValue, color: deploymentStatus == .deployed ? .sdkSuccess : .orange)
                    DetailMetricPill(label: "Branch", value: selectedBranch, color: .teal)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear).listRowInsets(EdgeInsets())

            CurrentReleaseSection(connector: connector, status: $deploymentStatus)

            branchSection

            Section("Version History") {
                if versionHistory.count == 1 { Text("Only the current saved version is available.").font(.caption).foregroundStyle(.secondary) }
                ForEach(versionHistory) { entry in
                    VersionHistoryRow(entry: entry, isCurrent: entry.version == connector.version, onRollback: { rollbackTarget = $0; showingRollbackAlert = true })
                }
            }

            tagsSection

            Section("Configuration Diff") {
                VStack(alignment: .leading, spacing: 8) {
                    DiffItem(label: "Endpoints", value: "\(connector.endpoints.count)")
                    DiffItem(label: "Flow Steps", value: "\(connector.flow.steps.count)")
                    DiffItem(label: "Auth Type", value: connector.authConfig.type.rawValue.capitalized)
                    DiffItem(label: "Schema Mappings", value: "\(connector.schema.mappings.count)")
                }.padding(.vertical, 4)
            }

            versioningSettingsSection

            Section {
                Button(action: { newVersion = incrementVersion(connector.version); showingReleaseSheet = true }) { Label("Create New Release", systemImage: "arrow.up.circle.fill").font(.subheadline.bold()) }
                Button(action: { showingCompare = true }) { Label("Compare Changes", systemImage: "arrow.left.arrow.right") }
                Button { showingChangelogGenerator = true } label: { Label("Generate Changelog", systemImage: "doc.text") }
            }
        }
        .listStyle(.insetGrouped).navigationTitle("Versioning").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingBranchManager = true } label: { Label("Branch Manager", systemImage: "arrow.triangle.branch") }
                    Button { showingTagManager = true } label: { Label("Tag Manager", systemImage: "tag") }
                    Button { showingChangelogGenerator = true } label: { Label("Changelog", systemImage: "doc.text") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingReleaseSheet) { ReleaseManagementSheet(connector: connector, newVersion: $newVersion, notes: $releaseNotes, onPublish: { connector.version = newVersion; deploymentStatus = .deployed; manager.updateConnector(connector); showingReleaseSheet = false }).presentationDetents([.large]) }
        .sheet(isPresented: $showingCompare) { CompareVersionsSheet(history: versionHistory).presentationDetents([.large]) }
        .sheet(isPresented: $showingBranchManager) {
            NavigationStack { branchManagerSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTagManager) {
            NavigationStack { tagManagerSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingChangelogGenerator) {
            NavigationStack { changelogSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Rollback to v\(rollbackTarget)?", isPresented: $showingRollbackAlert) { Button("Cancel", role: .cancel) {}; Button("Rollback", role: .destructive) { connector.version = rollbackTarget; deploymentStatus = .rollback; manager.updateConnector(connector) } } message: { Text("This will revert the active configuration.") }
    }

    // MARK: - Branch Section

    private var branchSection: some View {
        Section("Branches") {
            Picker("Active Branch", selection: $selectedBranch) {
                ForEach(branches, id: \.name) { branch in
                    Text(branch.name).tag(branch.name)
                }
            }
            ForEach(branches, id: \.name) { branch in
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(branch.isDefault ? .green : .secondary)
                    Text(branch.name).font(.subheadline)
                    if branch.isDefault {
                        Text("default").font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.green.opacity(0.15), in: Capsule())
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Text(branch.lastActivity.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        Section("Tags") {
            if tags.isEmpty {
                Text("No tags created").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(tags) { tag in
                    HStack {
                        Image(systemName: "tag.fill").foregroundStyle(.orange)
                        Text(tag.name).font(.subheadline)
                        Spacer()
                        Text("v\(tag.version)").font(.caption2.monospaced()).foregroundStyle(.secondary)
                    }
                }
                .onDelete { tags.remove(atOffsets: $0) }
            }
            HStack {
                TextField("Tag name", text: $newTagName).font(.caption)
                Button {
                    tags.append(VersionTag(name: newTagName, version: connector.version, date: Date()))
                    newTagName = ""
                } label: { Image(systemName: "plus.circle.fill") }
                .disabled(newTagName.isEmpty)
            }
        }
    }

    // MARK: - Versioning Settings

    private var versioningSettingsSection: some View {
        Section("Versioning Settings") {
            Toggle("Auto-Versioning", isOn: $enableAutoVersioning)
            Picker("Strategy", selection: $versioningStrategy) {
                ForEach(VersioningStrategy.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
        }
    }

    // MARK: - Sheets

    private var branchManagerSheet: some View {
        List {
            ForEach(branches, id: \.name) { branch in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(branch.name).font(.subheadline.bold())
                        if branch.isDefault { Text("default").font(.caption2).foregroundStyle(.green) }
                    }
                    Text("Last activity: \(branch.lastActivity.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Branch Manager")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tagManagerSheet: some View {
        List {
            ForEach(tags) { tag in
                LabeledContent(tag.name) {
                    VStack(alignment: .trailing) {
                        Text("v\(tag.version)").font(.caption.monospaced())
                        Text(tag.date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { tags.remove(atOffsets: $0) }
        }
        .navigationTitle("Tag Manager")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var changelogSheet: some View {
        Form {
            Section("Generated Changelog") {
                Text("## v\(connector.version)")
                    .font(.headline)
                Text("Released: \(connector.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundStyle(.secondary)
                Text("### Changes")
                    .font(.subheadline.bold())
                Text("- \(connector.endpoints.count) endpoints configured")
                    .font(.caption)
                Text("- \(connector.flow.steps.count) flow steps defined")
                    .font(.caption)
                Text("- Auth: \(connector.authConfig.type.rawValue.capitalized)")
                    .font(.caption)
                Text("- Schema: \(connector.schema.mappings.count) mappings")
                    .font(.caption)
            }
            Section {
                Button("Copy Changelog") {
                    let changelog = "## v\(connector.version)\nReleased: \(connector.updatedAt.formatted(date: .abbreviated, time: .omitted))\n\n### Changes\n- \(connector.endpoints.count) endpoints\n- \(connector.flow.steps.count) flow steps\n- Auth: \(connector.authConfig.type.rawValue)\n- \(connector.schema.mappings.count) schema mappings"
                    UIPasteboard.general.string = changelog
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Changelog")
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Version Models

private struct VersionBranch {
    let name: String
    let isDefault: Bool
    let lastActivity: Date
}

private struct VersionTag: Identifiable {
    let id = UUID()
    let name: String
    let version: String
    let date: Date
}

private enum VersioningStrategy: String, CaseIterable {
    case semantic = "Semantic"
    case calver = "CalVer"
    case incremental = "Incremental"
}
