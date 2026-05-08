import SwiftUI

struct SDKScopesEditorView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var showingReview = false

    private var categories: [(String, [SDKScopeDefinition])] {
        Dictionary(grouping: SDKRuntimeWorkspaceState.scopeCatalog, by: \.category)
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted { $0.key < $1.key }) }
    }

    private var enabledScopes: Set<String> { state.effectiveScopes(for: projectManager.currentProject) }
    private var isCompact: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SDK Permissions")
                            .font(.headline)
                        Text("These grants are used by SDK dependency validation and selected run configurations.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(enabledScopes.count)")
                        .font(.title3.bold())
                        .foregroundStyle(.accent)
                }
                Button("Review Effective Scope Set") { showingReview = true }
            }

            ForEach(categories, id: \.0) { category, items in
                Section(category) {
                    ForEach(items) { item in
                        scopeRow(item)
                    }
                }
            }

            if !scopeDiagnostics.isEmpty {
                Section("SDK Validation") {
                    ForEach(scopeDiagnostics) { diagnostic in
                        Button { state.open(node: diagnostic.node) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Label(diagnostic.message, systemImage: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                                Text(diagnostic.suggestion)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Auto Resolve Required Scopes") { autoResolveScopeSuggestions() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
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
        .onAppear { state.recalculateDiagnostics() }
        .navigationTitle("Scopes")
    }

    private func scopeRow(_ item: SDKScopeDefinition) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Toggle(isOn: binding(for: item.key)) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.key)
                        .font(.system(.subheadline, design: .monospaced))
                        .lineLimit(isCompact ? 2 : 1)
                    Spacer(minLength: 8)
                    Text(item.riskLevel)
                        .font(.caption2.bold())
                        .foregroundStyle(riskColor(item.riskLevel))
                }
            }
            Text(item.description).font(.caption).foregroundStyle(.secondary)
            if isCompact {
                VStack(alignment: .leading, spacing: 3) {
                    Label(item.approvals, systemImage: "person.badge.shield.checkmark")
                    Label(item.linkedCapability.title, systemImage: item.linkedCapability.icon)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else {
                HStack {
                    Label(item.approvals, systemImage: "person.badge.shield.checkmark")
                    Spacer()
                    Label(item.linkedCapability.title, systemImage: item.linkedCapability.icon)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            if !item.dependsOn.isEmpty {
                Text("Depends on: \(item.dependsOn.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
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

    private func riskColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }
}
