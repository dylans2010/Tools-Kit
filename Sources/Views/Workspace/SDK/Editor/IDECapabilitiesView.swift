/*
 REDESIGN SUMMARY:
 - Standardized on a responsive grid layout using ScrollView and LazyVGrid.
 - Replaced manual capability cards with a private CapabilityCard struct.
 - Standardized status indicators using native Label and semantic colors.
 - Improved visual hierarchy for required scopes using monospaced typography and status dots.
 - strictly preserved all SDKRuntimeWorkspaceState scope validation logic.
 - Replaced manual section headers with standard system typography.
 */

import SwiftUI

struct IDECapabilitiesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: .infinity), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Capability Matrix")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(SDKRuntimeWorkspaceState.capabilityCatalog) { capability in
                        CapabilityCard(capability: capability,
                                       effectiveScopes: state.effectiveScopes(for: projectManager.currentProject))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Capabilities")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Private Subviews

private struct CapabilityCard: View {
    let capability: SDKCapabilityDefinition
    let effectiveScopes: Set<String>

    var isEnabled: Bool {
        Set(capability.requiredScopes).isSubset(of: effectiveScopes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: capability.node.icon)
                    .font(.title2)
                    .foregroundStyle(isEnabled ? .accentColor : .secondary)
                Spacer()
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "lock.fill")
                    .foregroundStyle(isEnabled ? .green : .secondary)
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

            VStack(alignment: .leading, spacing: 6) {
                Text("Required Scopes")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                ForEach(capability.requiredScopes, id: \.self) { scope in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(effectiveScopes.contains(scope) ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(scope)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(effectiveScopes.contains(scope) ? .primary : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isEnabled ? Color.accentColor.opacity(0.1) : Color.clear, lineWidth: 1)
        )
    }
}
