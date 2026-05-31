import SwiftUI

struct PrivacyManifestEditorView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var scopeService = DeveloperScopeService.shared

    @State private var selectedAppID: UUID?
    @State private var apiUsageReasons: [String: String] = [:]
    @State private var justifications: [String: String] = [:]

    var app: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppID }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                appSelector

                if let app = app {
                    VStack(alignment: .leading, spacing: 20) {
                        manifestHeader

                        criticalScopesSection(app)

                        SectionHeader(title: "API Usage Reasons", subtitle: "Declare reasons for using sensitive system APIs.", icon: "doc.text.fill")
                        apiUsageGrid
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
            Text("Automated scan detected required declarations for your requested scopes.")
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
            SectionHeader(title: "High Risk Scopes", subtitle: "Additional justification required for platform audit.", icon: "exclamationmark.shield.fill")

            if criticalScopes.isEmpty {
                Text("No high-risk scopes detected.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(criticalScopes) { scope in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(scope.name).font(.subheadline.bold())
                            Spacer()
                            Text(scope.riskLevel.rawValue).font(.system(size: 8, weight: .bold)).foregroundStyle(.red)
                        }

                        Text("Explain how your app uses '\(scope.id)':").font(.caption).bold()
                        TextEditor(text: Binding(
                            get: { justifications[scope.id] ?? "" },
                            set: { justifications[scope.id] = $0 }
                        ))
                        .frame(height: 80)
                        .font(.caption)
                        .padding(4)
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
            apiUsageRow(title: "File Timestamp", icon: "clock.fill", reason: "Required for cache validation and file integrity checks.")
            apiUsageRow(title: "System Boot Time", icon: "power", reason: "Used for measuring system performance and cold-start latency.")
            apiUsageRow(title: "User Defaults", icon: "gearshape.fill", reason: "Standard storage for user preferences and application state.")
        }
    }

    private func apiUsageRow(title: String, icon: String, reason: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).font(.title3).foregroundStyle(.secondary).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(reason).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: .constant(true)).labelsHidden().scaleEffect(0.8)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
