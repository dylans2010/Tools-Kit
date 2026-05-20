
import SwiftUI

struct SecurityScopeApplicationView: View {
    @Binding var plugin: PluginDefinition
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthorizationManager.shared

    @State private var dataMinimizationEnabled = true
    @State private var encryptionRequired = true
    @State private var thirdPartyDisclosure = false
    @State private var auditLoggingEnabled = true
    @State private var safetyChecksEnabled = true

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("High risk permissions and sensitive workspace access require additional security information and justification.")
                        .font(.subheadline).foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "shield.checkered").foregroundStyle(.green)
                        Text("Encryption Active").font(.caption2.bold())
                        Spacer()
                        Image(systemName: "lock.shield.fill").foregroundStyle(.blue)
                        Text("Hardware Isolated").font(.caption2.bold())
                    }
                    .padding(8)
                    .background(Color.accentColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
            } header: {
                Label("Security Scope Gate", systemImage: "lock.trianglebadge.exclamationmark")
            }
            .listRowBackground(Color.clear)

            Section {
                LabeledContent {
                    if let key = plugin.apiKey {
                        Text(key).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                    } else {
                        Button {
                            plugin.apiKey = "tk_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
                        } label: {
                            Label("Generate Secure Key", systemImage: "key.fill")
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                    }
                } label: {
                    Label("API Key", systemImage: "key.horizontal.fill")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Privacy Note", systemImage: "doc.text.fill").font(.caption.bold()).foregroundStyle(.secondary)
                    TextEditor(text: Binding(get: { plugin.privacyNote ?? "" }, set: { plugin.privacyNote = $0.isEmpty ? nil : $0 }))
                        .frame(minHeight: 80)
                        .padding(4)
                        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                }
            } header: {
                Label("Credentials & Identification", systemImage: "person.badge.shield.checkmark.fill")
            } footer: {
                Text("Publicly visible justification for accessing sensitive data.")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Usage Explanation", systemImage: "questionmark.circle.fill").font(.caption.bold()).foregroundStyle(.secondary)
                    TextField("How will this data be used?", text: Binding(get: { plugin.dataUsageExplanation ?? "" }, set: { plugin.dataUsageExplanation = $0.isEmpty ? nil : $0 }))
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Label("Retention Policy", systemImage: "clock.fill").font(.caption.bold()).foregroundStyle(.secondary)
                    TextField("How long is data stored?", text: Binding(get: { plugin.retentionPolicy ?? "" }, set: { plugin.retentionPolicy = $0.isEmpty ? nil : $0 }))
                        .textFieldStyle(.roundedBorder)
                }
            } header: {
                Label("Data Governance", systemImage: "hand.raised.fill")
            }

            Section {
                Toggle(isOn: $dataMinimizationEnabled) {
                    Label("Data Minimization", systemImage: "sieve.fill")
                }
                Toggle(isOn: $encryptionRequired) {
                    Label("End-to-End Encryption", systemImage: "lock.shield.fill")
                }
                Toggle(isOn: $thirdPartyDisclosure) {
                    Label("Third-party Disclosure", systemImage: "network.badge.shield.half.filled")
                }
                Toggle(isOn: $auditLoggingEnabled) {
                    Label("Security Audit Logging", systemImage: "list.bullet.indent")
                }
                Toggle(isOn: $safetyChecksEnabled) {
                    Label("Real-time Safety Checks", systemImage: "waveform.path.ecg.rectangle.fill")
                }
            } header: {
                Label("Advanced Security Controls", systemImage: "slider.horizontal.3")
            } footer: {
                Text("Enable advanced protocols to ensure maximum security for high-risk operations.")
            }

            Section {
                ForEach(plugin.capabilities) { cap in
                    HStack {
                        VStack(alignment: .leading) {
                            Label(cap.displayName, systemImage: cap.icon).font(.subheadline.bold())
                            Text(cap.technicalKey).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
                        }
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
                    ContentUnavailableView("No Scopes Requested", systemImage: "shield.slash", description: Text("This plugin does not currently request any system scopes."))
                        .scaleEffect(0.8)
                }
            } header: {
                Label("Scope Authorization Status", systemImage: "shield.checkered")
            } footer: {
                Text("Changes are applied to the plugin definition. High risk plugins without an API Key or Privacy Note will be blocked during installation or execution.")
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
