import SwiftUI

struct SDKScopesEditorView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    struct ScopeCategory: Identifiable {
        let id = UUID()
        let name: String
        let items: [ScopeItem]
    }

    struct ScopeItem: Identifiable {
        let id = UUID()
        let key: String
        let description: String
        let riskLevel: String
        let approvals: String
        let linkedCapabilities: String
        let dependsOn: [String]
    }

    private var categories: [ScopeCategory] {
        [
            ScopeCategory(name: "Data", items: [
                .init(key: "workspace.files.read", description: "Read project files", riskLevel: "Low", approvals: "None", linkedCapabilities: "Config", dependsOn: []),
                .init(key: "workspace.files.write", description: "Write project files", riskLevel: "Medium", approvals: "Maintainer", linkedCapabilities: "Runtime Scripts", dependsOn: ["workspace.files.read"])
            ]),
            ScopeCategory(name: "AI", items: [
                .init(key: "workspace.persona.read", description: "Use persona context", riskLevel: "Medium", approvals: "Maintainer", linkedCapabilities: "Capabilities", dependsOn: []),
                .init(key: "workspace.persona.write", description: "Persist persona memory", riskLevel: "High", approvals: "Security review", linkedCapabilities: "Libraries", dependsOn: ["workspace.persona.read"])
            ]),
            ScopeCategory(name: "Automation", items: [
                .init(key: "workspace.automation.execute", description: "Run workflow scripts", riskLevel: "High", approvals: "Maintainer", linkedCapabilities: "Runtime Scripts", dependsOn: ["workspace.files.read"])
            ]),
            ScopeCategory(name: "Integrations", items: [
                .init(key: "external.api.unrestricted", description: "External connector access", riskLevel: "High", approvals: "Security review", linkedCapabilities: "Connectors", dependsOn: [])
            ]),
            ScopeCategory(name: "System", items: [
                .init(key: "workspace.runtime.admin", description: "Runtime administration", riskLevel: "Critical", approvals: "Admin", linkedCapabilities: "Run Config", dependsOn: ["workspace.files.read", "workspace.automation.execute"])
            ])
        ]
    }

    var body: some View {
        List {
            ForEach(categories) { category in
                Section(category.name) {
                    ForEach(category.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: binding(for: item.key)) {
                                HStack {
                                    Text(item.key).font(.system(.subheadline, design: .monospaced))
                                    Spacer()
                                    Text(item.riskLevel)
                                        .font(.caption2.bold())
                                        .foregroundStyle(riskColor(item.riskLevel))
                                }
                            }
                            Text(item.description).font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Text("Approvals: \(item.approvals)")
                                Spacer()
                                Text("Capability: \(item.linkedCapabilities)")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                            if !item.dependsOn.isEmpty {
                                Text("Depends on: \(item.dependsOn.joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !scopeDiagnostics.isEmpty {
                Section("Conflict Detection") {
                    ForEach(scopeDiagnostics) { diagnostic in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(diagnostic.message)
                                .font(.caption)
                            Text(diagnostic.suggestion)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Auto Resolve Suggestions") {
                        autoResolveScopeSuggestions()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear { state.recalculateDiagnostics() }
        .navigationTitle("Scopes")
    }

    private var scopeDiagnostics: [SDKRuntimeDiagnostic] {
        state.diagnostics.filter { $0.node == .scopes }
    }

    private func binding(for scope: String) -> Binding<Bool> {
        Binding(
            get: { projectManager.currentProject?.enabledScopes.contains(scope) == true },
            set: { enabled in
                guard var project = projectManager.currentProject else { return }
                if enabled {
                    if !project.enabledScopes.contains(scope) { project.enabledScopes.append(scope) }
                } else {
                    project.enabledScopes.removeAll { $0 == scope }
                }
                projectManager.updateProject(project)
                state.recalculateDiagnostics()
            }
        )
    }

    private func autoResolveScopeSuggestions() {
        guard var project = projectManager.currentProject else { return }
        for library in state.libraries {
            for scope in library.linkedScopes where !project.enabledScopes.contains(scope) {
                project.enabledScopes.append(scope)
            }
        }
        projectManager.updateProject(project)
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
