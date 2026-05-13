

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
                Label("Security Scope Gate", systemImage: "lock.trianglebadge.exclamationmark")
            }
            .listRowBackground(Color.clear)

            Section {
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
            } header: {
                Label("Credentials & Identification", systemImage: "key.fill")
            } footer: {
                Text("Justification for accessing sensitive data.")
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Usage Explanation").font(.caption.bold()).foregroundStyle(.secondary)
                    TextField("How will this data be used?", text: Binding(get: { plugin.dataUsageExplanation ?? "" }, set: { plugin.dataUsageExplanation = $0.isEmpty ? nil : $0 }))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Retention Policy").font(.caption.bold()).foregroundStyle(.secondary)
                    TextField("How long is data stored?", text: Binding(get: { plugin.retentionPolicy ?? "" }, set: { plugin.retentionPolicy = $0.isEmpty ? nil : $0 }))
                }
            } header: {
                Label("Data Governance", systemImage: "hand.raised.fill")
            }

            Section {
                let highRiskCapabilities = plugin.capabilities.filter { $0.riskLevel == .high }
                let usedScopes = AuthorizationManager.shared.currentScopes()

                if highRiskCapabilities.isEmpty {
                    Text("No high-risk scopes requested.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(highRiskCapabilities) { cap in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label(cap.displayName, systemImage: cap.icon).font(.subheadline)
                                Spacer()
                                let isUsed = usedScopes.contains(where: { $0.contains(cap.rawValue) })

                                Text(isUsed ? "ACTIVE" : "PENDING")
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background((isUsed ? Color.green : Color.orange).opacity(0.1), in: Capsule())
                                    .foregroundStyle(isUsed ? .green : .orange)

                                Text("HIGH RISK")
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.red.opacity(0.1), in: Capsule())
                                    .foregroundStyle(.red)
                            }

                            if !usedScopes.contains(where: { $0.contains(cap.rawValue) }) {
                                Text("Scope requested but not yet granted in current session.")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Label("Scope Status", systemImage: "exclamationmark.shield.fill")
            } footer: {
                Text("Changes are applied to the plugin definition. High-risk plugins without an API Key or Privacy Note will be blocked during installation or execution.")
            }

            Section("Unavailable Scopes") {
                let allScopes = PluginCapability.allCases.map { $0.rawValue }
                let currentScopes = AuthorizationManager.shared.currentScopes()
                let unavailable = allScopes.filter { scope in
                    !currentScopes.contains { $0 == "*" || $0 == scope || (scope.contains(".") && $0 == scope.split(separator: ".").first! + ".*") }
                }

                if unavailable.isEmpty {
                    Text("All system scopes are available.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(unavailable, id: \.self) { scope in
                        HStack {
                            Text(scope).font(.caption.monospaced())
                            Spacer()
                            Image(systemName: "lock.slash.fill").foregroundStyle(.secondary).font(.caption2)
                        }
                    }
                }
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
