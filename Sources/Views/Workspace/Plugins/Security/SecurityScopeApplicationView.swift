

import SwiftUI

struct SecurityScopeApplicationView: View {
    @Binding var plugin: PluginDefinition
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthorizationManager.shared

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
                ForEach(plugin.capabilities) { cap in
                    HStack {
                        Label(cap.displayName, systemImage: cap.icon).font(.subheadline)
                        Spacer()

                        let isGranted = authManager.validateScope(cap.technicalKey)

                        if cap.riskLevel == .high || cap.riskLevel == .critical {
                            Text(cap.riskLevel.rawValue.uppercased())
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.red.opacity(0.1), in: Capsule())
                                .foregroundStyle(.red)
                        }

                        Image(systemName: isGranted ? "checkmark.shield.fill" : "xmark.shield.fill")
                            .foregroundStyle(isGranted ? .green : .red)
                    }
                }

                if plugin.capabilities.isEmpty {
                    Text("No scopes requested.").font(.caption).foregroundStyle(.secondary)
                }
            } header: {
                Label("Scope Authorization Status", systemImage: "shield.checkered")
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
