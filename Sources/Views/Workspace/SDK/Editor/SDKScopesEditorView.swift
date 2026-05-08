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
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Effective Scopes").font(.headline)
                            Text("Aggregated permissions for the current workspace context.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SDKStatusPill("\(enabledScopes.count) GRANTS", systemImage: "key.fill", color: .blue)
                    }

                    Button { showingReview = true } label: {
                        HStack {
                            Label("Audit Permissions", systemImage: "shield.lefthalf.filled")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.bold())
                        .padding()
                        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Security", subtitle: "Workspace entitlement management", systemImage: "lock.shield.fill")
            }

            ForEach(categories, id: \.0) { category, items in
                Section {
                    ForEach(items) { item in
                        scopeRow(item)
                    }
                } header: {
                    HStack {
                        Image(systemName: "folder.badge.lock")
                        Text(category.uppercased())
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                }
            }

            if !scopeDiagnostics.isEmpty {
                Section {
                    ForEach(scopeDiagnostics) { diagnostic in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(diagnostic.severity == .error ? .red : .orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(diagnostic.message)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(diagnostic.suggestion)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        autoResolveScopeSuggestions()
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Auto-Resolve All Issues")
                        }
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Color(.systemBackground))
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                } header: {
                    Text("VALIDATION ISSUES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.key)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                    Text(item.description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: binding(for: item.key))
                    .labelsHidden()
                    .tint(.blue)
            }

            HStack {
                SDKStatusPill(item.riskLevel, color: riskColor(item.riskLevel), isCapsule: false)

                Spacer()

                HStack(spacing: 12) {
                    Label(item.approvals, systemImage: "person.badge.shield.checkmark")
                    Label(item.linkedCapability.title, systemImage: item.linkedCapability.icon)
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
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
