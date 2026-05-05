import SwiftUI

struct PluginLimitedView: View {
    let plugin: PluginDefinition
    let reason: ValidationFailureReason
    let detail: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                restrictionSummaryPanel

                unmetRequirementsSection

                resolutionActionsSection

                developerExplanationPanel
            }
            .padding()
        }
        .navigationTitle("Limited Execution")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: plugin.icon)
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 80, height: 80)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name)
                    .font(.title3.bold())
                Text(plugin.identifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var restrictionSummaryPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Execution Blocked: \(reason.rawValue)")
                    .font(.headline)
            }

            Text("This plugin cannot execute fully in your current workspace environment.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var unmetRequirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unmet Requirements")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                requirementRow(title: "Specific Capability", met: reason != .capabilityMismatch)
                requirementRow(title: "Action Access", met: reason != .actionMismatch)
                requirementRow(title: "Security Scopes", met: reason != .scopeInvalid)
                requirementRow(title: "System Services", met: reason != .prerequisitesUnmet)
                requirementRow(title: "Execution Rules", met: reason != .ruleBlocked)
            }
        }
    }

    private func requirementRow(title: String, met: Bool) -> some View {
        HStack {
            Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(met ? .green : .red)
            Text(title)
                .font(.subheadline)
            Spacer()
            if !met {
                Text("Missing").font(.caption).foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private var resolutionActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resolution Actions")
                .font(.headline)

            VStack(spacing: 12) {
                resolutionButton(title: "Check System Settings", icon: "gearshape")
                resolutionButton(title: "Enable Required Services", icon: "bolt.fill")
                resolutionButton(title: "Update Plugin Permissions", icon: "shield.fill")
                resolutionButton(title: "View Execution Logs", icon: "terminal")
            }
        }
    }

    private func resolutionButton(title: String, icon: String) -> some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var developerExplanationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Developer Context")
                .font(.headline)

            Text(detail)
                .font(.system(.caption, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.05))
                .cornerRadius(8)

            Text("Degraded execution is enforced to ensure workspace safety. Some features may be unavailable until requirements are met.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
