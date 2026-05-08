import SwiftUI

struct SDKCapabilitiesMatrixView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var selectedCapability: SDKCapabilityDefinition?

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Runtime Capability Matrix", systemImage: "square.grid.3x3.fill")
                        .font(.headline)
                    Spacer()
                    Text("\(enabledCount)/\(SDKRuntimeWorkspaceState.capabilityCatalog.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                Text("Capabilities are backed by SDK scope validation, dependency planning, and library execution state.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Capabilities") {
                ForEach(SDKRuntimeWorkspaceState.capabilityCatalog) { capability in
                    Button { selectedCapability = capability } label: {
                        capabilityRow(capability)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Conflict Markers") {
                if dependencyConflicts.isEmpty {
                    Text("No capability conflicts detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dependencyConflicts, id: \.self) { message in
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .sheet(item: $selectedCapability) { capability in
            NavigationStack {
                capabilityDetail(capability)
                    .navigationTitle(capability.node.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { selectedCapability = nil } } }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .navigationTitle("Capabilities")
    }

    private var effectiveScopes: Set<String> { state.effectiveScopes(for: projectManager.currentProject) }
    private var enabledCount: Int { SDKRuntimeWorkspaceState.capabilityCatalog.filter { Set($0.requiredScopes).isSubset(of: effectiveScopes) }.count }
    private var dependencyConflicts: [String] { SDKDependencyConflictResolver().conflicts(in: state.dependencies) }

    private func capabilityRow(_ capability: SDKCapabilityDefinition) -> some View {
        let isEnabled = Set(capability.requiredScopes).isSubset(of: effectiveScopes)
        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(capability.node.title, systemImage: capability.node.icon)
                    .font(.headline)
                Spacer()
                runtimeImpactLabel(for: capability)
            }
            Text(capability.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                heatmap(usage: usageIntensity(for: capability))
                Spacer()
                Label(isEnabled ? "Ready" : "Needs scopes", systemImage: isEnabled ? "checkmark.seal.fill" : "lock.trianglebadge.exclamationmark")
                    .font(.caption2.bold())
                    .foregroundStyle(isEnabled ? .green : .orange)
            }
        }
        .padding(.vertical, 5)
    }

    private func capabilityDetail(_ capability: SDKCapabilityDefinition) -> some View {
        List {
            Section("SDK Integration") {
                Text(capability.description)
                ForEach(capability.requiredScopes, id: \.self) { scope in
                    HStack {
                        Text(scope).font(.system(.caption, design: .monospaced))
                        Spacer()
                        if effectiveScopes.contains(scope) { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                    }
                }
                Button("Open Related Workspace") {
                    state.open(node: capability.node)
                    selectedCapability = nil
                }
            }
            Section("Runtime Usage") {
                LabeledContent("Dependencies", value: "\(state.dependencies.count)")
                LabeledContent("Libraries", value: "\(state.libraries.count)")
                LabeledContent("Diagnostics", value: "\(state.diagnostics.filter { $0.node == capability.node }.count)")
            }
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

    private func heatmap(usage: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < min(5, max(1, usage)) ? .red.opacity(0.75) : .gray.opacity(0.25))
                    .frame(width: 14, height: 8)
            }
        }
    }

    private func runtimeImpactLabel(for capability: SDKCapabilityDefinition) -> some View {
        let impact = usageIntensity(for: capability)
        return Text(impact > 6 ? "High" : impact > 2 ? "Medium" : "Low")
            .font(.caption2.bold())
            .foregroundStyle(impact > 6 ? .red : impact > 2 ? .orange : .green)
    }
}
