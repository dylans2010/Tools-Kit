import SwiftUI

struct SecurityScopeApplicationView: View {
    @Binding var plugin: PluginDefinition

    @Environment(\.dismiss) private var dismiss
    @State private var showingKeyGenerator = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Security Scope Gate")
                        .font(.headline)
                    Text("High-risk permissions and sensitive workspace access require additional security information.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Credentials & Identification") {
                HStack {
                    Text("API Key")
                    Spacer()
                    if let key = plugin.apiKey {
                        Text(key)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else {
                        Button("Generate") {
                            plugin.apiKey = "tk_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Note")
                        .font(.caption.bold())
                    TextEditor(text: Binding(
                        get: { plugin.privacyNote ?? "" },
                        set: { plugin.privacyNote = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.separator), lineWidth: 0.5))
                    Text("Justification for accessing sensitive data.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Data Governance") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage Explanation")
                        .font(.caption.bold())
                    TextField("How will this data be used?", text: Binding(
                        get: { plugin.dataUsageExplanation ?? "" },
                        set: { plugin.dataUsageExplanation = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Retention Policy")
                        .font(.caption.bold())
                    TextField("How long is data stored?", text: Binding(
                        get: { plugin.retentionPolicy ?? "" },
                        set: { plugin.retentionPolicy = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.subheadline)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Requested High-Risk Scopes")
                        .font(.subheadline.bold())

                    let highRiskCapabilities = plugin.capabilities.filter { $0.riskLevel == .high }

                    if highRiskCapabilities.isEmpty {
                        Text("No high-risk scopes requested.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(highRiskCapabilities) { cap in
                            HStack {
                                Label(cap.displayName, systemImage: cap.icon)
                                    .font(.caption)
                                Spacer()
                                Text("HIGH RISK")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            } footer: {
                Text("Changes are applied to the plugin definition. High-risk plugins without an API Key or Privacy Note will be blocked during installation or execution.")
            }
        }
        .navigationTitle("Security Scope")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { dismiss() }
            }
        }
    }
}
