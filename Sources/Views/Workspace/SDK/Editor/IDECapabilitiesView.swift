import SwiftUI

struct IDECapabilitiesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared

    var body: some View {
        List {
            Section(header: Text("Capability Summary")) {
                let scopes = state.effectiveScopes(for: projectManager.currentProject)
                let enabled = SDKRuntimeWorkspaceState.capabilityCatalog.filter { Set($0.requiredScopes).isSubset(of: scopes) }
                LabeledContent("Enabled", value: "\(enabled.count)")
                LabeledContent("Total", value: "\(SDKRuntimeWorkspaceState.capabilityCatalog.count)")
            }

            Section(header: Text("Capabilities")) {
                ForEach(SDKRuntimeWorkspaceState.capabilityCatalog) { capability in
                    CapabilityRow(
                        capability: capability,
                        effectiveScopes: state.effectiveScopes(for: projectManager.currentProject)
                    )
                }
            }
        }
        .navigationTitle("Capabilities")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CapabilityRow: View {
    let capability: SDKCapabilityDefinition
    let effectiveScopes: Set<String>

    var isEnabled: Bool {
        Set(capability.requiredScopes).isSubset(of: effectiveScopes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(capability.node.title, systemImage: capability.node.icon)
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "lock.fill")
                    .foregroundStyle(isEnabled ? Color.green : Color.secondary)
            }

            Text(capability.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if !capability.requiredScopes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Required Scopes")
                        .font(.caption2.bold())
                        .foregroundStyle(.tertiary)

                    ForEach(Array(capability.requiredScopes), id: \.self) { (scope: String) in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(effectiveScopes.contains(scope) ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            Text(scope)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(effectiveScopes.contains(scope) ? Color.primary : Color.red)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
