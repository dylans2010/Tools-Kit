

import SwiftUI

struct SDKCapabilitiesMatrixView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var selectedCapability: SDKCapabilityDefinition?

    private var effectiveScopes: Set<String> { state.effectiveScopes(for: projectManager.currentProject) }
    private var enabledCount: Int { SDKRuntimeWorkspaceState.capabilityCatalog.filter { Set($0.requiredScopes).isSubset(of: effectiveScopes) }.count }
    private var dependencyConflicts: [String] { SDKDependencyConflictResolver().conflicts(in: state.dependencies) }

    var body: some View {
        List {
            Section("Runtime Status") {
                LabeledContent("Active Features") {
                    Text("\(enabledCount) / \(SDKRuntimeWorkspaceState.capabilityCatalog.count)")
                        .font(.headline.monospaced())
                        .foregroundStyle(Color.accentColor)
                }
            }

            Section("Capability Matrix") {
                ForEach(SDKRuntimeWorkspaceState.capabilityCatalog) { capability in
                    CapabilityRow(capability: capability,
                                 effectiveScopes: effectiveScopes,
                                 usageIntensity: usageIntensity(for: capability)) {
                        selectedCapability = capability
                    }
                }
            }

            if !dependencyConflicts.isEmpty {
                Section("Integrity Issues") {
                    ForEach(dependencyConflicts, id: \.self) { message in
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Capabilities")
        .sheet(item: $selectedCapability) { capability in
            NavigationStack {
                CapabilityDetail(capability: capability, effectiveScopes: effectiveScopes, state: state)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { selectedCapability = nil }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
    }

    private func usageIntensity(for capability: SDKCapabilityDefinition) -> Int {
        switch capability.node {
        case .libraries: return state.libraries.reduce(0) { $0 + $1.exportedFunctions.count }
        case .dependencies: return state.dependencies.count
        case .scopes: return effectiveScopes.count
        case .connectors: return SDKConnectorManager.shared.connectors.count
        default: return max(1, state.dependencies.count / 2)
        }
    }
}

// MARK: - Private Subviews

private struct CapabilityRow: View {
    let capability: SDKCapabilityDefinition
    let effectiveScopes: Set<String>
    let usageIntensity: Int
    let action: () -> Void

    var isEnabled: Bool { Set(capability.requiredScopes).isSubset(of: effectiveScopes) }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(capability.node.title, systemImage: capability.node.icon)
                        .font(.headline)
                    Spacer()
                    Image(systemName: isEnabled ? "checkmark.seal.fill" : "lock.fill")
                        .foregroundStyle(isEnabled ? Color.green : Color.secondary)
                }

                Text(capability.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text("Impact: \(impactLabel)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(impactColor)

                    Spacer()

                    Text("\(usageIntensity) active links")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var impactLabel: String {
        usageIntensity > 6 ? "High" : usageIntensity > 2 ? "Medium" : "Low"
    }

    private var impactColor: Color {
        usageIntensity > 6 ? .red : usageIntensity > 2 ? .orange : .green
    }
}

private struct CapabilityDetail: View {
    let capability: SDKCapabilityDefinition
    let effectiveScopes: Set<String>
    let state: SDKRuntimeWorkspaceState

    var body: some View {
        List {
            Section("About") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(capability.description)
                        .font(.subheadline)

                    Button {
                        state.open(node: capability.node)
                    } label: {
                        Label("Open Dedicated Editor", systemImage: "arrow.up.right.square")
                            .font(.caption.bold())
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Required Scopes") {
                ForEach(capability.requiredScopes, id: \.self) { scope in
                    LabeledContent {
                        Image(systemName: effectiveScopes.contains(scope) ? "checkmark.circle.fill" : "lock.fill")
                            .foregroundStyle(effectiveScopes.contains(scope) ? Color.green : Color.orange)
                    } label: {
                        Text(scope).font(.caption.monospaced())
                    }
                }
            }

            Section("Runtime Usage") {
                LabeledContent("Active Dependencies", value: "\(state.dependencies.filter { $0.requiredScopes.contains { capability.requiredScopes.contains($0) } }.count)")
                LabeledContent("Linked Libraries", value: "\(state.libraries.filter { $0.linkedScopes.contains { capability.requiredScopes.contains($0) } }.count)")

                let diagnosticCount = state.diagnostics.filter { $0.node == capability.node }.count
                LabeledContent("Current Issues") {
                    Text("\(diagnosticCount)")
                        .foregroundStyle(diagnosticCount > 0 ? Color.red : Color.green)
                        .bold()
                }
            }
        }
        .navigationTitle(capability.node.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
