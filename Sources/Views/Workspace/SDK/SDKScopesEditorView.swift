import SwiftUI

struct SDKScopesEditorView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var showingReview = false

    private var categories: [(String, [SDKScopeDefinition])] {
        Dictionary(grouping: SDKRuntimeWorkspaceState.scopeCatalog, by: \.category)
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted { $0.key < $1.key }) }
    }

    private var enabledScopes: Set<String> { state.effectiveScopes(for: projectManager.currentProject) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SDKSectionHeader(
                    title: "SDK Permissions",
                    subtext: "Grants used by SDK dependency validation and selected run configurations."
                )

                SDKModernCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Effective Scope Set").font(.subheadline.bold())
                            Text("\(enabledScopes.count) scopes enabled").sdkSubtext()
                        }
                        Spacer()
                        Button("Review") { showingReview = true }
                            .buttonStyle(.bordered)
                    }
                }

                ForEach(categories, id: \.0) { category, items in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category).font(.caption.bold()).foregroundStyle(.secondary).padding(.leading, 4)

                        VStack(spacing: 12) {
                            ForEach(items) { item in
                                scopeCard(item)
                            }
                        }
                    }
                }

                if !scopeDiagnostics.isEmpty {
                    SDKSectionHeader(title: "SDK Validation", subtext: "Issues detected in scope configuration.")

                    VStack(spacing: 12) {
                        ForEach(scopeDiagnostics) { diagnostic in
                            SDKModernCard {
                                HStack(spacing: 12) {
                                    Image(systemName: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                        .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(diagnostic.message).font(.subheadline.bold())
                                        Text(diagnostic.suggestion).sdkSubtext()
                                    }
                                    Spacer()
                                }
                            }
                        }

                        Button("Auto Resolve") { autoResolveScopeSuggestions() }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Scopes")
        .sheet(isPresented: $showingReview) {
            NavigationStack {
                List {
                    Section("Effective scopes") {
                        ForEach(enabledScopes.sorted(), id: \.self) { scope in
                            Text(scope).font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                .navigationTitle("SDK Scope Review")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showingReview = false } } }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func scopeCard(_ item: SDKScopeDefinition) -> some View {
        SDKModernCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.key).font(.system(.subheadline, design: .monospaced)).bold()
                    Spacer()
                    SDKStatusPill(status: riskToStatus(item.riskLevel), text: item.riskLevel.uppercased())
                }

                Text(item.description).sdkSubtext()

                Divider()

                HStack {
                    Toggle("Enabled", isOn: binding(for: item.key))
                        .labelsHidden()
                    Text("Enable Scope").font(.caption.bold())
                    Spacer()
                    Label(item.approvals, systemImage: "person.badge.shield.checkmark").font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var scopeDiagnostics: [SDKRuntimeDiagnostic] {
        state.diagnostics.filter { $0.node == .scopes || $0.message.contains("scope") }
    }

    private func binding(for scope: String) -> Binding<Bool> {
        Binding(
            get: { projectManager.currentProject?.enabledScopes.contains(scope) == true },
            set: { state.setScope(scope, enabled: $0, for: projectManager) }
        )
    }

    private func autoResolveScopeSuggestions() {
        guard var project = projectManager.currentProject else { return }
        for library in state.libraries {
            for scope in library.linkedScopes { state.grantScope(scope, to: &project) }
        }
        for capability in SDKRuntimeWorkspaceState.capabilityCatalog {
            for scope in capability.requiredScopes { state.grantScope(scope, to: &project) }
        }
        projectManager.updateProject(project)
        state.syncSDKGraphFromProject(project)
        state.recalculateDiagnostics()
    }

    private func riskToStatus(_ level: String) -> SDKStatus {
        switch level.lowercased() {
        case "critical": return .error
        case "high": return .warning
        case "medium": return .warning
        default: return .success
        }
    }
}
