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
                        Text("SDK Permissions").font(.headline)
                        Text("Active grants used by dependency validation.").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    SDKStatusPill("\(enabledScopes.count)", systemImage: "key.fill", color: .blue)
                }
                Button { showingReview = true } label: {
                    Label("Review Effective Scope Set", systemImage: "checklist.checked")
                        .font(.subheadline.bold())
                }
            } header: {
                SDKSectionHeader("Access Control", subtitle: "Managed security boundaries", systemImage: "lock.shield.fill")
            }

            ForEach(categories, id: \.0) { category, items in
                Section {
                    ForEach(items) { item in
                        scopeRow(item)
                    }
                } header: {
                    SDKSectionHeader(category, subtitle: "Permission group", alignment: .leading)
                }
            }

            if !scopeDiagnostics.isEmpty {
                Section {
                    ForEach(scopeDiagnostics) { diagnostic in
                        Button { state.open(node: diagnostic.node) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Label(diagnostic.message, systemImage: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(diagnostic.severity == .error ? .sdkError : .sdkWarning)
                                Text(diagnostic.suggestion)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button {
                        autoResolveScopeSuggestions()
                    } label: {
                        Label("Auto-Resolve Diagnostics", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .padding(.vertical, 4)
                } header: {
                    SDKSectionHeader("SDK Validation", subtitle: "Security and dependency issues", systemImage: "checkmark.seal.fill")
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
        SDKModernCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: binding(for: item.key)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.key)
                            .font(.system(.subheadline, design: .monospaced))
                            .bold()
                        Text(item.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)

                HStack {
                    SDKStatusPill(item.riskLevel, color: riskColor(item.riskLevel), isCapsule: false)

                    Spacer()

                    HStack(spacing: 12) {
                        Label(item.approvals, systemImage: "person.badge.shield.checkmark")
                        Label(item.linkedCapability.title, systemImage: item.linkedCapability.icon)
                    }
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                }

                if !item.dependsOn.isEmpty {
                    Text("Dependencies: \(item.dependsOn.joined(separator: ", "))")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 4)
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
