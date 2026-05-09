/*
 REDESIGN SUMMARY:
 - Standardized on a modern, center-aligned status layout.
 - Replaced manual panels with native SwiftUI containers (Form/List) where appropriate.
 - Modernized the restriction summary using a prominent background panel with semantic colors.
 - Standardized requirement rows using Label with semantic SF Symbols.
 - Replaced manual resolution buttons with a native List/Section for actions.
 - strictly preserved all PluginDefinition and ValidationFailureReason logic.
 - Improved visual hierarchy for developer context (monospaced logs).
 - Added ContentUnavailableView-inspired header for consistency.
 */

import SwiftUI

struct PluginLimitedView: View {
    let plugin: PluginDefinition
    let reason: ValidationFailureReason
    let detail: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: plugin.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(.accent)
                        .frame(width: 80, height: 80)
                        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))

                    VStack(spacing: 4) {
                        Text(plugin.name).font(.headline)
                        Text(plugin.identifier).font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Execution Blocked: \(reason.rawValue)", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline).foregroundStyle(.orange)
                    Text("This extension cannot execute fully in your current workspace environment due to unmet security or capability requirements.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.orange.opacity(0.05))

            Section("Compliance Status") {
                RequirementRow(title: "Specific Capability", met: reason != .capabilityMismatch)
                RequirementRow(title: "Action Access", met: reason != .actionMismatch)
                RequirementRow(title: "Security Scopes", met: reason != .scopeInvalid)
                RequirementRow(title: "System Services", met: reason != .prerequisitesUnmet)
            }

            Section("Resolution Actions") {
                NavigationLink(destination: Text("System Settings")) {
                    Label("Check System Settings", systemImage: "gearshape")
                }
                NavigationLink(destination: Text("Service Status")) {
                    Label("Enable Required Services", systemImage: "bolt.fill")
                }
                NavigationLink(destination: Text("Permission Editor")) {
                    Label("Update Plugin Permissions", systemImage: "shield.fill")
                }
            }

            Section("Developer Context") {
                Text(detail)
                    .font(.system(.caption, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
            } footer: {
                Text("Degraded execution is enforced to ensure workspace safety. Some features may be unavailable until requirements are met.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Limited Execution")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct RequirementRow: View {
    let title: String
    let met: Bool
    var body: some View {
        Label {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                if !met { Text("Missing").font(.caption2.bold()).foregroundStyle(.red) }
            }
        } icon: {
            Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(met ? .green : .red)
        }
    }
}
