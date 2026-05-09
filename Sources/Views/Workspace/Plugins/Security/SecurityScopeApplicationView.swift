/*
 REDESIGN SUMMARY:
 - Standardized on native Form architecture.
 - Modernized the header using a native Section footer for descriptive text.
 - Replaced manual API key generator with a structured LabeledContent row.
 - Standardized the Privacy Note editor with native TextEditor and improved focus styling.
 - Replaced manual high-risk scope list with a native Section using semantic SF Symbols and colors.
 - strictly preserved all PluginDefinition binding and API key generation logic.
 - Improved visual hierarchy for credentials and data governance.
 - Standardized the toolbar actions.
 */

import SwiftUI

struct SecurityScopeApplicationView: View {
    @Binding var plugin: PluginDefinition
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text("High-risk permissions and sensitive workspace access require additional security information and justification.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } header: {
                Text("Security Scope Gate")
            }
            .listRowBackground(Color.clear)

            Section("Credentials & Identification") {
                LabeledContent("API Key") {
                    if let key = plugin.apiKey {
                        Text(key).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                    } else {
                        Button("Generate Key") {
                            plugin.apiKey = "tk_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Note").font(.caption.bold()).foregroundStyle(.secondary)
                    TextEditor(text: Binding(get: { plugin.privacyNote ?? "" }, set: { plugin.privacyNote = $0.isEmpty ? nil : $0 }))
                        .frame(minHeight: 100)
                        .padding(4)
                        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                }
            } footer: {
                Text("Justification for accessing sensitive data.")
            }

            Section("Data Governance") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Usage Explanation").font(.caption.bold()).foregroundStyle(.secondary)
                    TextField("How will this data be used?", text: Binding(get: { plugin.dataUsageExplanation ?? "" }, set: { plugin.dataUsageExplanation = $0.isEmpty ? nil : $0 }))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Retention Policy").font(.caption.bold()).foregroundStyle(.secondary)
                    TextField("How long is data stored?", text: Binding(get: { plugin.retentionPolicy ?? "" }, set: { plugin.retentionPolicy = $0.isEmpty ? nil : $0 }))
                }
            }

            Section("Requested High-Risk Scopes") {
                let highRiskCapabilities = plugin.capabilities.filter { $0.riskLevel == .high }
                if highRiskCapabilities.isEmpty {
                    Text("No high-risk scopes requested.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(highRiskCapabilities) { cap in
                        HStack {
                            Label(cap.displayName, systemImage: cap.icon).font(.subheadline)
                            Spacer()
                            Text("HIGH RISK")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.red.opacity(0.1), in: Capsule())
                                .foregroundStyle(.red)
                        }
                    }
                }
            } footer: {
                Text("Changes are applied to the plugin definition. High-risk plugins without an API Key or Privacy Note will be blocked during installation or execution.")
            }
        }
        .navigationTitle("Security Scopes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { dismiss() }.bold()
            }
        }
    }
}
