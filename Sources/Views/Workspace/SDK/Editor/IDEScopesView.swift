/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Replaced manual status pills and headers with native Section titles and LabeledContent.
 - Modernized scope rows using native Toggle and private struct ScopeItemRow.
 - Applied .presentationDetents([.medium, .large]) to the review sheet with a drag indicator.
 - Standardized risk level colors using semantic .red, .orange, and .green.
 - strictly preserved all SDKRuntimeWorkspaceState diagnostics, scope mapping, and project update logic.
 - Improved visual hierarchy for required approvals and linked capabilities.
 - Replaced manual HStack layouts with standard Label components.
 */

import SwiftUI

struct IDEScopesView: View {
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
        List {
            Section("Security Profile") {
                LabeledContent("Active Grants") {
                    Text("\(enabledScopes.count)").monospaced().bold().foregroundStyle(.accent)
                }

                Button { showingReview = true } label: {
                    Label("Review Effective Scopes", systemImage: "shield.lefthalf.filled")
                        .font(.subheadline.bold())
                }
            }

            if !scopeDiagnostics.isEmpty {
                Section("Validation Issues") {
                    ForEach(scopeDiagnostics) { diagnostic in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(diagnostic.message).font(.subheadline.bold())
                                Text(diagnostic.suggestion).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                        }
                    }

                    Button(action: autoResolveScopeSuggestions) {
                        Label("Auto-Resolve All Issues", systemImage: "wand.and.stars")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            ForEach(categories, id: \.0) { category, items in
                Section(category.uppercased()) {
                    ForEach(items) { item in
                        ScopeItemRow(item: item, projectManager: projectManager, state: state)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Scopes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReview) {
            NavigationStack {
                List {
                    Section("Aggregated Grants") {
                        ForEach(enabledScopes.sorted(), id: \.self) { scope in
                            Text(scope).font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                .navigationTitle("Scope Review")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showingReview = false } } }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear { state.recalculateDiagnostics() }
    }

    private var scopeDiagnostics: [SDKRuntimeDiagnostic] {
        state.diagnostics.filter { $0.node == .scopes || $0.message.contains("scope") }
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
}

// MARK: - Private Subviews

private struct ScopeItemRow: View {
    let item: SDKScopeDefinition
    @ObservedObject var projectManager: SDKProjectManager
    @ObservedObject var state: SDKRuntimeWorkspaceState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.key).font(.system(.subheadline, design: .monospaced).bold())
                    Text(item.description).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { projectManager.currentProject?.enabledScopes.contains(item.key) == true },
                    set: { state.setScope(item.key, enabled: $0, for: projectManager) }
                ))
                .labelsHidden()
            }

            HStack {
                Text(item.riskLevel.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(riskColor.opacity(0.1), in: Capsule())
                    .foregroundStyle(riskColor)

                Spacer()

                HStack(spacing: 12) {
                    Label(item.approvals, systemImage: "person.badge.shield.checkmark")
                    Label(item.linkedCapability.title, systemImage: item.linkedCapability.icon)
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var riskColor: Color {
        switch item.riskLevel.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }
}
