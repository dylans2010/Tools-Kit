import SwiftUI

struct SDKCapabilitiesMatrixView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var selectedCapability: SDKCapabilityDefinition?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SDKSectionHeader(
                    title: "Runtime Capabilities",
                    subtext: "System features driven by permissions, libraries, and dependencies."
                )

                SDKModernCard {
                    HStack(spacing: 20) {
                        statView(label: "Enabled", value: "\(enabledCount)", color: .green)
                        statView(label: "Total", value: "\(SDKRuntimeWorkspaceState.capabilityCatalog.count)", color: .secondary)
                        statView(label: "Conflicts", value: "\(dependencyConflicts.count)", color: dependencyConflicts.isEmpty ? .green : .orange)
                    }
                }

                SDKSectionHeader(title: "Capability Matrix", subtext: "Tap a capability to view SDK integration details.")

                VStack(spacing: 12) {
                    ForEach(SDKRuntimeWorkspaceState.capabilityCatalog) { capability in
                        Button { selectedCapability = capability } label: {
                            capabilityCard(capability)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !dependencyConflicts.isEmpty {
                    SDKSectionHeader(title: "Conflicts", subtext: "Runtime dependency mismatches.")
                    VStack(spacing: 12) {
                        ForEach(dependencyConflicts, id: \.self) { message in
                            SDKModernCard {
                                Label(message, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .sdkWarningText()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Capabilities")
        .sheet(item: $selectedCapability) { capability in
            NavigationStack {
                capabilityDetail(capability)
                    .navigationTitle(capability.node.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { selectedCapability = nil } } }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var effectiveScopes: Set<String> { state.effectiveScopes(for: projectManager.currentProject) }
    private var enabledCount: Int { SDKRuntimeWorkspaceState.capabilityCatalog.filter { Set($0.requiredScopes).isSubset(of: effectiveScopes) }.count }
    private var dependencyConflicts: [String] { SDKDependencyConflictResolver().conflicts(in: state.dependencies) }

    private func capabilityCard(_ capability: SDKCapabilityDefinition) -> some View {
        let isEnabled = Set(capability.requiredScopes).isSubset(of: effectiveScopes)
        return SDKModernCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(capability.node.title, systemImage: capability.node.icon)
                        .font(.subheadline.bold())
                    Spacer()
                    SDKStatusPill(status: isEnabled ? .success : .warning, text: isEnabled ? "READY" : "LOCKED")
                }

                Text(capability.description).sdkSubtext().lineLimit(2)

                HStack {
                    heatmap(usage: usageIntensity(for: capability))
                    Spacer()
                    Text(impactLevel(for: capability)).font(.caption2.bold()).foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func capabilityDetail(_ capability: SDKCapabilityDefinition) -> some View {
        List {
            Section("SDK Integration") {
                Text(capability.description).font(.subheadline)
                ForEach(capability.requiredScopes, id: \.self) { scope in
                    HStack {
                        Text(scope).font(.system(.caption, design: .monospaced))
                        Spacer()
                        if effectiveScopes.contains(scope) {
                            Image(systemName: "checkmark.circle.fill").sdkSuccessText()
                        } else {
                            Image(systemName: "lock.fill").foregroundStyle(.secondary)
                        }
                    }
                }
                Button("Open Related Workspace") {
                    state.open(node: capability.node)
                    selectedCapability = nil
                }
            }
            Section("Runtime Metrics") {
                LabeledContent("Dependencies", value: "\(state.dependencies.count)")
                LabeledContent("Libraries", value: "\(state.libraries.count)")
                LabeledContent("Diagnostics", value: "\(state.diagnostics.filter { $0.node == capability.node }.count)")
            }
        }
    }

    private func statView(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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

    private func impactLevel(for capability: SDKCapabilityDefinition) -> String {
        let impact = usageIntensity(for: capability)
        return impact > 6 ? "High Impact" : impact > 2 ? "Medium Impact" : "Low Impact"
    }

    private func heatmap(usage: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < min(5, max(1, usage)) ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(width: 14, height: 8)
            }
        }
    }
}
