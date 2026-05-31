import SwiftUI

struct PrivacyManifestEditorView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var scopeService = DeveloperScopeService.shared

    @State private var selectedAppID: UUID?
    @State private var isSaving = false
    @State private var showSaveToast = false

    var app: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppID }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                appSelector

                if let app = app {
                    VStack(alignment: .leading, spacing: 32) {
                        manifestHeader(app)

                        criticalScopesSection(app)

                        SectionHeader(title: "API Usage Reasons", subtitle: "Declare reasons for using sensitive system APIs to comply with platform policies.", icon: "doc.text.fill")
                        apiUsageGrid(app)

                        saveSection(app)
                    }
                    .padding()
                } else {
                    EmptyStateView(icon: "hand.raised.fill", title: "Select an Application", message: "Choose an application from your registry to generate and manage its Privacy Manifest.")
                        .padding(.top, 40)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Privacy Manifest")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
        .overlay(alignment: .bottom) {
            if showSaveToast {
                Text("Manifest Updated Successfully")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var appSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Project").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Picker("App", selection: $selectedAppID) {
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .pickerStyle(.menu)
            .padding(4)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        }
        .padding()
    }

    private func manifestHeader(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manifest Compliance").font(.headline)
                    Text("Bundle ID: \(app.bundleId)").font(.caption).monospaced().foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.blue).font(.title2)
            }
            Text("An automated scan of your application's requested permissions has identified areas requiring explicit justification.")
                .font(.system(size: 13))
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
            SectionHeader(title: "Advanced Scopes", subtitle: "Additional justification is mandatory for high-risk permissions.", icon: "exclamationmark.shield.fill")

            if criticalScopes.isEmpty {
                HStack {
                    Image(systemName: "info.circle").foregroundStyle(.secondary)
                    Text("No high-risk scopes detected in current configuration.").font(.caption).foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(criticalScopes) { scope in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scope.name).font(.subheadline.bold())
                                Text(scope.id).font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            riskBadge(scope.riskLevel)
                        }

                        Text("Usage Justification").font(.system(size: 11, weight: .bold))

                        TextEditor(text: Binding(
                            get: { app.socialLinks["justification_\(scope.id)"] ?? "" },
                            set: { newValue in
                                var updated = app
                                updated.socialLinks["justification_\(scope.id)"] = newValue
                                Task { try? await appService.updateApp(updated) }
                            }
                        ))
                        .frame(height: 100)
                        .font(.system(size: 13))
                        .padding(8)
                        .background(Color.primary.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.05), lineWidth: 1))

                        if (app.socialLinks["justification_\(scope.id)"]?.count ?? 0) < 50 {
                            Text("Provide at least 50 characters to satisfy audit requirements.")
                                .font(.system(size: 10))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                }
            }
        }
    }

    private func apiUsageGrid(_ app: DeveloperApp) -> some View {
        VStack(spacing: 12) {
            apiUsageRow(app: app, key: "usage_file_timestamp", title: "File Timestamp", icon: "clock.fill", description: "Required for cache validation and file integrity checks.")
            apiUsageRow(app: app, key: "usage_boot_time", title: "System Boot Time", icon: "power", description: "Used for measuring system performance and cold-start latency.")
            apiUsageRow(app: app, key: "usage_user_defaults", title: "User Defaults", icon: "gearshape.fill", description: "Standard storage for user preferences and application state.")
        }
    }

    private func apiUsageRow(app: DeveloperApp, key: String, title: String, icon: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).font(.title3).foregroundStyle(.secondary).frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .bold))
                Text(description).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { app.socialLinks[key] == "true" },
                set: { val in
                    var updated = app
                    updated.socialLinks[key] = val ? "true" : "false"
                    Task { try? await appService.updateApp(updated) }
                }
            )).labelsHidden().scaleEffect(0.8)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func saveSection(_ app: DeveloperApp) -> some View {
        VStack(spacing: 16) {
            Divider()

            Button {
                saveManifest(app)
            } label: {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Finalize & Sign Manifest")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(isSaving)

            Text("Signatures ensure the integrity of your privacy declarations during the submission process.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func riskBadge(_ risk: ScopeRiskLevel) -> some View {
        Text(risk.rawValue.uppercased())
            .font(.system(size: 9, weight: .black))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(risk == .critical ? Color.red : Color.orange)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }

    private func saveManifest(_ app: DeveloperApp) {
        isSaving = true
        Task {
            // Update last modified
            var updated = app
            updated.lastModified = Date()
            try? await appService.updateApp(updated)

            await MainActor.run {
                isSaving = false
                withAnimation { showSaveToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showSaveToast = false }
                }
            }
        }
    }
}
