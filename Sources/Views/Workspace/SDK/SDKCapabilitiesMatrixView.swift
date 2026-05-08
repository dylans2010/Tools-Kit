import SwiftUI

struct SDKCapabilitiesMatrixView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var selectedCapability: SDKCapabilityDefinition?

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Capability Matrix").font(.headline)
                        Text("Live SDK feature availability based on granted scopes.").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    SDKStatusPill("\(enabledCount)/\(SDKRuntimeWorkspaceState.capabilityCatalog.count)", systemImage: "bolt.fill", color: .blue)
                }
            } header: {
                SDKSectionHeader("Runtime Status", subtitle: "System-level capability validation", systemImage: "square.grid.3x3.fill")
            }

            Section {
                ForEach(SDKRuntimeWorkspaceState.capabilityCatalog) { capability in
                    Button { selectedCapability = capability } label: {
                        capabilityRow(capability)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                SDKSectionHeader("Capabilities", subtitle: "Managed SDK functionality modules", systemImage: "circle.grid.cross.fill")
            }

            Section {
                if dependencyConflicts.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.sdkSuccess)
                        Text("No capability conflicts detected").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                } else {
                    ForEach(dependencyConflicts, id: \.self) { message in
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.sdkWarning)
                    }
                }
            } header: {
                SDKSectionHeader("Integrity", subtitle: "Conflict detection and resolution", systemImage: "shield.fill")
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
        return SDKModernCard(padding: 12, content: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(capability.node.title, systemImage: capability.node.icon)
                        .font(.subheadline.bold())
                    Spacer()
                    runtimeImpactLabel(for: capability)
                }

                Text(capability.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack {
                    heatmap(usage: usageIntensity(for: capability))
                    Spacer()
                    SDKStatusPill(
                        isEnabled ? "Ready" : "Restricted",
                        systemImage: isEnabled ? "checkmark.seal.fill" : "lock.fill",
                        color: isEnabled ? .sdkSuccess : .sdkWarning
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func capabilityDetail(_ capability: SDKCapabilityDefinition) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(capability.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SDKSectionHeader("Required Scopes", subtitle: "Permissions needed for this capability", alignment: .leading)

                    ForEach(capability.requiredScopes, id: \.self) { scope in
                        HStack {
                            Text(scope).font(.system(.caption, design: .monospaced))
                            Spacer()
                            if effectiveScopes.contains(scope) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.sdkSuccess)
                            } else {
                                Image(systemName: "lock.fill").foregroundStyle(.sdkWarning).font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                SDKSectionHeader("Integration Details", subtitle: "SDK binding configuration", systemImage: "link")
            }

            Section {
                Button {
                    state.open(node: capability.node)
                    selectedCapability = nil
                } label: {
                    Label("Open Dedicated Editor", systemImage: "arrow.up.right.square")
                        .font(.subheadline.bold())
                }
            }

            Section {
                LabeledContent("Active Dependencies", value: "\(state.dependencies.filter { $0.requiredScopes.contains { capability.requiredScopes.contains($0) } }.count)")
                LabeledContent("Linked Libraries", value: "\(state.libraries.filter { $0.linkedScopes.contains { capability.requiredScopes.contains($0) } }.count)")
                let diagnosticCount = state.diagnostics.filter { $0.node == capability.node }.count
                LabeledContent("Current Issues") {
                    Text("\(diagnosticCount)")
                        .foregroundStyle(diagnosticCount > 0 ? .sdkError : .sdkSuccess)
                        .bold()
                }
            } header: {
                SDKSectionHeader("Runtime Usage", subtitle: "Live SDK execution metrics", systemImage: "chart.bar.fill")
            }
        }
        .background(Color(.systemGroupedBackground))
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
