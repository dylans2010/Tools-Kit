import SwiftUI

struct PrivacyManifestEditorView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var scopeService = DeveloperScopeService.shared

    @State private var selectedAppID: UUID?
    @State private var apiUsageReasons: [String: Bool] = [:]
    @State private var justifications: [String: String] = [:]
    @State private var showingExportModal = false

    var app: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppID }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                appSelector

                if let app = app {
                    VStack(alignment: .leading, spacing: 32) {
                        manifestHeader

                        criticalScopesSection(app)

                        SectionHeader(title: "API Usage Reasons", subtitle: "Declare reasons for using sensitive system APIs.", icon: "doc.text.fill")
                        apiUsageGrid

                        saveButton
                    }
                    .padding()
                } else {
                    EmptyStateView(icon: "hand.raised.fill", title: "Select an Application", message: "Choose an application to generate its Privacy Manifest.")
                        .padding(.top, 40)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Privacy Manifest")
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
            loadManifestData()
        }
        .onChange(of: selectedAppID) { _ in
            loadManifestData()
        }
    }

    private var appSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Project").font(.caption.bold()).foregroundStyle(.secondary)
            Picker("App", selection: $selectedAppID) {
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .pickerStyle(.menu)
            .padding(10)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }

    private var manifestHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Manifest Compliance").font(.headline)
                Spacer()
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.blue)
            }
            Text("Automated scan detected required declarations for your requested scopes. Advanced scopes require manual justification.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func criticalScopesSection(_ app: DeveloperApp) -> some View {
        let criticalScopes = app.grantedScopes.compactMap { scopeService.fetchScope(identifier: $0) }
            .filter { $0.riskLevel == .high || $0.riskLevel == .critical }

        return VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Advanced Scopes", subtitle: "Additional justification required for platform audit.", icon: "exclamationmark.shield.fill")

            if criticalScopes.isEmpty {
                Text("No advanced scopes detected in this project.").font(.caption).foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(criticalScopes) { scope in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scope.name).font(.subheadline.bold())
                                Text(scope.id).font(.caption2.monospaced()).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text(scope.riskLevel.rawValue.uppercased()).font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .clipShape(Capsule())
                        }

                        Text("Justification for '\(scope.id)':").font(.caption).bold()
                        TextEditor(text: Binding(
                            get: { justifications[scope.id] ?? "" },
                            set: { justifications[scope.id] = $0 }
                        ))
                        .frame(height: 80)
                        .font(.caption)
                        .padding(8)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var apiUsageGrid: some View {
        VStack(spacing: 12) {
            apiUsageRow(id: "file_timestamp", title: "File Timestamp", icon: "clock.fill", reason: "Required for cache validation and file integrity checks.")
            apiUsageRow(id: "boot_time", title: "System Boot Time", icon: "power", reason: "Used for measuring system performance and cold-start latency.")
            apiUsageRow(id: "user_defaults", title: "User Defaults", icon: "gearshape.fill", reason: "Standard storage for user preferences and application state.")
            apiUsageRow(id: "disk_space", title: "Disk Space", icon: "internaldrive.fill", reason: "Determines available space for content downloads.")
        }
    }

    private func apiUsageRow(id: String, title: String, icon: String, reason: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).font(.title3).foregroundStyle(.secondary).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(reason).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { apiUsageReasons[id] ?? false },
                set: { apiUsageReasons[id] = $0 }
            )).labelsHidden().scaleEffect(0.8)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var saveButton: some View {
        Button {
            saveManifest()
        } label: {
            Text("Update Privacy Manifest")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func loadManifestData() {
        guard let app = app else { return }
        // In a real app, this would load from a PrivacyManifest model in the store.
        // For this task, we will simulate the dynamic data handling.
        justifications = [:]
        apiUsageReasons = [:]

        // Populate with existing data if available (this logic would be in a service)
        for scope in app.grantedScopes {
            justifications[scope] = "Used for core application functionality and security verification."
        }
        apiUsageReasons["file_timestamp"] = true
        apiUsageReasons["user_defaults"] = true
    }

    private func saveManifest() {
        guard let app = app else { return }
        // Create manifest object and save to store
        let manifest = PrivacyManifest(
            appID: app.id,
            apiUsageReasons: apiUsageReasons.filter { $0.value }.map { $0.key },
            justifications: justifications
        )
        // Task { try? await appService.updatePrivacyManifest(manifest) }
        showingExportModal = true
    }
}

public struct PrivacyManifest: Codable {
    public var appID: UUID
    public var apiUsageReasons: [String]
    public var justifications: [String: String]
}
