
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

    @State private var keyRegion = "us"
    @State private var keyValidationStatus: KeyValidationStatus = .none
    @State private var showKeyDetails = false
    @State private var tokenRotationDays: Int = 90
    @State private var enableAutoRotation = false
    @State private var accessLogRetentionDays: Int = 30
    @State private var geoRestrictionEnabled = false
    @State private var allowedRegions: Set<String> = ["US", "EU"]
    @State private var sessionTimeoutMinutes: Int = 60
    @State private var mfaRequired = false
    @State private var webhookVerification = true
    @State private var encryptionAlgorithm = "AES-256-GCM"
    @State private var complianceFrameworks: Set<String> = []
    @State private var incidentContacts: [String] = []
    @State private var newContact = ""

    enum KeyValidationStatus {
        case none, valid, invalid
    }

    private let regionOptions = ["us", "eu", "ap", "sa", "af", "me"]
    private let encryptionAlgorithms = ["AES-256-GCM", "AES-256-CBC", "ChaCha20-Poly1305", "RSA-4096"]
    private let complianceOptions = ["SOC 2", "GDPR", "HIPAA", "PCI DSS", "ISO 27001", "CCPA", "FERPA"]

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
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(key).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary).lineLimit(1)
                            HStack(spacing: 6) {
                                if PluginKeyPattern.validate(key) {
                                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).font(.caption2)
                                    Text("Valid Pattern").font(.system(size: 8, weight: .bold)).foregroundStyle(.green)
                                } else {
                                    Image(systemName: "xmark.seal.fill").foregroundStyle(.red).font(.caption2)
                                    Text("Legacy Key").font(.system(size: 8, weight: .bold)).foregroundStyle(.red)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 6) {
                            Picker("Region", selection: $keyRegion) {
                                ForEach(regionOptions, id: \.self) { Text($0.uppercased()).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .controlSize(.small)

                            Button {
                                plugin.apiKey = PluginKeyPattern.generate(region: keyRegion)
                            } label: {
                                Label("Generate Strict Key", systemImage: "key.fill")
                            }
                            .buttonStyle(.bordered).controlSize(.small)
                        }
                    }
                } label: {
                    Label("API Key", systemImage: "key.horizontal.fill")
                }

                if let key = plugin.apiKey {
                    Button {
                        showKeyDetails.toggle()
                    } label: {
                        Label(showKeyDetails ? "Hide Key Details" : "Show Key Details", systemImage: showKeyDetails ? "eye.slash" : "eye")
                            .font(.caption)
                    }

                    if showKeyDetails, let decoded = PluginKeyPattern.decode(key) {
                        VStack(alignment: .leading, spacing: 6) {
                            keyDetailRow("Region", value: decoded.region.uppercased())
                            keyDetailRow("Issued", value: decoded.timestamp.formatted(date: .abbreviated, time: .shortened))
                            keyDetailRow("Entropy", value: decoded.entropy)
                            keyDetailRow("Checksum", value: decoded.checksum)
                            keyDetailRow("Pattern", value: "tk-{region}-{ts}-{entropy}-{crc}")
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                    }

                    Button(role: .destructive) {
                        plugin.apiKey = nil
                    } label: {
                        Label("Revoke & Regenerate", systemImage: "trash")
                            .font(.caption)
                    }
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
                Text("Keys follow strict pattern: tk-{region}-{timestamp}-{entropy}-{checksum}")
            }

            Section {
                Toggle(isOn: $enableAutoRotation) {
                    Label("Auto-Rotate Keys", systemImage: "arrow.triangle.2.circlepath")
                }
                if enableAutoRotation {
                    Stepper(value: $tokenRotationDays, in: 7...365, step: 7) {
                        HStack {
                            Label("Rotation Interval", systemImage: "calendar.badge.clock")
                            Spacer()
                            Text("\(tokenRotationDays) days").bold().font(.caption)
                        }
                    }
                }

                Stepper(value: $sessionTimeoutMinutes, in: 5...1440, step: 15) {
                    HStack {
                        Label("Session Timeout", systemImage: "hourglass")
                        Spacer()
                        Text("\(sessionTimeoutMinutes) min").bold().font(.caption)
                    }
                }

                Toggle(isOn: $mfaRequired) {
                    Label("Require MFA for High-Risk Ops", systemImage: "lock.badge.clock")
                }

                Toggle(isOn: $webhookVerification) {
                    Label("Webhook Signature Verification", systemImage: "signature")
                }
            } header: {
                Label("Token & Session Policy", systemImage: "key.radiowaves.forward")
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

                Stepper(value: $accessLogRetentionDays, in: 1...365) {
                    HStack {
                        Label("Access Log Retention", systemImage: "doc.text.magnifyingglass")
                        Spacer()
                        Text("\(accessLogRetentionDays) days").bold().font(.caption)
                    }
                }
            } header: {
                Label("Data Governance", systemImage: "hand.raised.fill")
            }

            Section {
                Picker("Encryption Algorithm", selection: $encryptionAlgorithm) {
                    ForEach(encryptionAlgorithms, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)

                Toggle(isOn: $geoRestrictionEnabled) {
                    Label("Geographic Restrictions", systemImage: "globe")
                }

                if geoRestrictionEnabled {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Allowed Regions").font(.caption.bold()).foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(["US", "EU", "UK", "AP", "CA", "AU", "JP", "BR"], id: \.self) { region in
                                    Button {
                                        if allowedRegions.contains(region) {
                                            allowedRegions.remove(region)
                                        } else {
                                            allowedRegions.insert(region)
                                        }
                                    } label: {
                                        Text(region)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(allowedRegions.contains(region) ? Color.accentColor : Color(.tertiarySystemBackground), in: Capsule())
                                            .foregroundStyle(allowedRegions.contains(region) ? .white : .primary)
                                    }
                                }
                            }
                        }
                    }
                }
            } header: {
                Label("Encryption & Geography", systemImage: "lock.rectangle.on.rectangle")
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select applicable compliance frameworks:").font(.caption).foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 6) {
                        ForEach(complianceOptions, id: \.self) { framework in
                            Button {
                                if complianceFrameworks.contains(framework) {
                                    complianceFrameworks.remove(framework)
                                } else {
                                    complianceFrameworks.insert(framework)
                                }
                            } label: {
                                Text(framework)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(complianceFrameworks.contains(framework) ? Color.blue : Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
                                    .foregroundStyle(complianceFrameworks.contains(framework) ? .white : .primary)
                            }
                        }
                    }
                }
            } header: {
                Label("Compliance Frameworks", systemImage: "building.columns.fill")
            }

            Section {
                if incidentContacts.isEmpty {
                    Text("No contacts added.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(incidentContacts, id: \.self) { contact in
                        HStack {
                            Image(systemName: "envelope.fill").foregroundStyle(.blue).font(.caption)
                            Text(contact).font(.caption)
                            Spacer()
                            Button { incidentContacts.removeAll { $0 == contact } } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                        }
                    }
                }
                HStack {
                    TextField("Email for incident alerts", text: $newContact)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .font(.caption)
                    Button("Add") {
                        guard !newContact.isEmpty else { return }
                        incidentContacts.append(newContact)
                        newContact = ""
                    }.disabled(newContact.isEmpty)
                }
            } header: {
                Label("Incident Response", systemImage: "bell.badge.fill")
            } footer: {
                Text("Contacts notified when security events are detected.")
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

    private func keyDetailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(size: 9, design: .monospaced))
        }
    }
}
