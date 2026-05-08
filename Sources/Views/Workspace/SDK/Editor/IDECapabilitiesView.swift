import SwiftUI

struct IDECapabilitiesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: .infinity), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SDKSectionHeader("Capabilities Matrix", subtitle: "SDK feature availability", systemImage: "square.grid.3x3.fill")
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(SDKRuntimeWorkspaceState.capabilityCatalog) { capability in
                        capabilityCard(for: capability)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Capabilities")
    }

    private func capabilityCard(for capability: SDKCapabilityDefinition) -> some View {
        let scopes = state.effectiveScopes(for: projectManager.currentProject)
        let missing = Set(capability.requiredScopes).subtracting(scopes)
        let isEnabled = missing.isEmpty

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: capability.node.icon)
                    .font(.title2)
                    .foregroundStyle(isEnabled ? .blue : .secondary)
                Spacer()
                if isEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(capability.node.title)
                    .font(.headline)
                Text(capability.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("REQUIRED SCOPES")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)

                ForEach(capability.requiredScopes, id: \.self) { scope in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(scopes.contains(scope) ? Color.green : Color.red)
                            .frame(width: 4, height: 4)
                        Text(scope)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(scopes.contains(scope) ? .primary : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isEnabled ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}
