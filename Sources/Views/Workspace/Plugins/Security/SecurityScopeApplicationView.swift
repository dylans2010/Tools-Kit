
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

    // Security Score
    @State private var showingSecurityReport = false
    @State private var showingAuditLog = false

    // Certificate Management
    @State private var certificates: [SecurityCertificate] = []
    @State private var showingAddCertificate = false
    @State private var certDomain = ""
    @State private var certExpiry: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var certPinningEnabled = true

    // OAuth Scope Management
    @State private var oauthScopes: [OAuthScopeEntry] = []
    @State private var newOAuthScope = ""
    @State private var oauthGrantType: OAuthGrantType = .authorizationCode

    // CORS Configuration
    @State private var corsEnabled = false
    @State private var corsAllowedOrigins: [String] = []
    @State private var corsAllowedMethods: Set<String> = ["GET", "POST"]
    @State private var corsAllowCredentials = false
    @State private var corsMaxAge: Int = 3600
    @State private var newCORSOrigin = ""

    // Content Filtering
    @State private var contentFilteringEnabled = false
    @State private var contentFilterRules: [ContentFilterRule] = []
    @State private var blockMaliciousPayloads = true
    @State private var sanitizeHTML = true
    @State private var maxPayloadSizeKB: Int = 1024

    // Data Classification
    @State private var dataClassificationTags: Set<String> = []
    @State private var defaultClassification: DataClassification = .internal

    // Breach Notification
    @State private var breachNotificationEnabled = true
    @State private var breachNotificationDelay: Int = 1
    @State private var breachAutoLockdown = true
    @State private var breachNotificationChannels: Set<String> = ["email"]

    // Access Control Lists
    @State private var aclEntries: [ACLEntry] = []
    @State private var newACLPrincipal = ""
    @State private var newACLPermission: ACLPermission = .read

    // Network Security
    @State private var tlsMinVersion: TLSVersion = .tls12
    @State private var enableHSTS = true
    @State private var hstsMaxAge: Int = 31536000
    @State private var enableCSP = true
    @State private var cspDirective = "default-src 'self'"

    // Vulnerability Scanning
    @State private var autoScanEnabled = false
    @State private var scanFrequencyDays: Int = 7
    @State private var lastScanDate: Date?
    @State private var vulnerabilityCount: Int = 0

    // Incident Playbook
    @State private var playbookSteps: [IncidentPlaybookStep] = []

    // Security Training
    @State private var securityTrainingCompleted = false
    @State private var trainingCompletionDate: Date?
    @State private var requiredTrainingModules: Set<String> = []

    // Secret Rotation History
    @State private var rotationHistory: [SecretRotationEntry] = []

    enum KeyValidationStatus {
        case none, valid, invalid
    }

    private let regionOptions = ["us", "eu", "ap", "sa", "af", "me"]
    private let encryptionAlgorithms = ["AES-256-GCM", "AES-256-CBC", "ChaCha20-Poly1305", "RSA-4096"]
    private let complianceOptions = ["SOC 2", "GDPR", "HIPAA", "PCI DSS", "ISO 27001", "CCPA", "FERPA"]
    private let httpMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]
    private let classificationOptions = ["Public", "Internal", "Confidential", "Restricted", "Top Secret"]
    private let trainingModules = ["Data Handling", "Incident Response", "Secure Coding", "Access Control", "Encryption Basics", "Social Engineering"]

    var body: some View {
        Form {
            // Security Score Header
            Section {
                SecurityScoreHeader(score: securityScore, grade: securityGrade)
            } header: {
                Label("Security Overview", systemImage: "shield.checkered")
            }
            .listRowBackground(Color.clear)

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
                            if let key = plugin.apiKey {
                                SecurityKeyStrengthIndicator(key: key)
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

            // Secret Rotation History
            Section {
                if rotationHistory.isEmpty {
                    Text("No rotation history available.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(rotationHistory) { entry in
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(entry.wasAutomatic ? .blue : .orange)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.wasAutomatic ? "Auto Rotation" : "Manual Rotation")
                                    .font(.caption.bold())
                                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.region.uppercased())
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                        }
                    }
                }
                Button("Rotate Now", systemImage: "arrow.clockwise") {
                    rotationHistory.insert(SecretRotationEntry(region: keyRegion, wasAutomatic: false), at: 0)
                }
                .font(.caption)
            } header: {
                Label("Rotation History", systemImage: "clock.arrow.2.circlepath")
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

            // Data Classification
            Section {
                Picker("Default Classification", selection: $defaultClassification) {
                    ForEach(DataClassification.allCases, id: \.self) { c in
                        HStack {
                            Circle().fill(c.color).frame(width: 8, height: 8)
                            Text(c.rawValue)
                        }.tag(c)
                    }
                }
                .pickerStyle(.menu)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Data Classification Tags").font(.caption.bold()).foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 6) {
                        ForEach(classificationOptions, id: \.self) { tag in
                            Button {
                                if dataClassificationTags.contains(tag) { dataClassificationTags.remove(tag) }
                                else { dataClassificationTags.insert(tag) }
                            } label: {
                                Text(tag)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(dataClassificationTags.contains(tag) ? Color.purple : Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
                                    .foregroundStyle(dataClassificationTags.contains(tag) ? .white : .primary)
                            }
                        }
                    }
                }
            } header: {
                Label("Data Classification", systemImage: "tag.fill")
            } footer: {
                Text("Classify the sensitivity of data this plugin processes.")
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

            // TLS & Transport Security
            Section {
                Picker("Minimum TLS Version", selection: $tlsMinVersion) {
                    ForEach(TLSVersion.allCases, id: \.self) { ver in
                        Text(ver.rawValue).tag(ver)
                    }
                }
                .pickerStyle(.menu)

                Toggle(isOn: $enableHSTS) {
                    Label("HTTP Strict Transport Security", systemImage: "lock.fill")
                }

                if enableHSTS {
                    Stepper(value: $hstsMaxAge, in: 3600...63072000, step: 86400) {
                        HStack {
                            Label("HSTS Max-Age", systemImage: "clock")
                            Spacer()
                            Text("\(hstsMaxAge / 86400) days").bold().font(.caption)
                        }
                    }
                }

                Toggle(isOn: $enableCSP) {
                    Label("Content Security Policy", systemImage: "shield.lefthalf.filled")
                }

                if enableCSP {
                    TextField("CSP Directive", text: $cspDirective)
                        .font(.system(.caption, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                }
            } header: {
                Label("Transport Security", systemImage: "network.badge.shield.half.filled")
            } footer: {
                Text("TLS 1.2 or higher is recommended. HSTS prevents protocol downgrade attacks.")
            }

            // Certificate Management
            Section {
                Toggle(isOn: $certPinningEnabled) {
                    Label("Certificate Pinning", systemImage: "pin.fill")
                }

                if certificates.isEmpty {
                    Text("No certificates configured.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(certificates) { cert in
                        HStack {
                            Image(systemName: cert.isExpired ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                                .foregroundStyle(cert.isExpired ? .red : .green)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cert.domain).font(.caption.bold())
                                Text("Expires: \(cert.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2).foregroundStyle(cert.isExpired ? .red : .secondary)
                            }
                            Spacer()
                            Text(cert.isExpired ? "Expired" : "Valid")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(cert.isExpired ? Color.red.opacity(0.12) : Color.green.opacity(0.12), in: Capsule())
                                .foregroundStyle(cert.isExpired ? .red : .green)
                        }
                    }
                    .onDelete { certificates.remove(atOffsets: $0) }
                }

                HStack {
                    TextField("Domain", text: $certDomain)
                        .textInputAutocapitalization(.never).font(.caption.monospaced())
                    Button("Add") {
                        certificates.append(SecurityCertificate(domain: certDomain, expiryDate: certExpiry))
                        certDomain = ""
                    }.disabled(certDomain.isEmpty)
                }
            } header: {
                Label("Certificate Management", systemImage: "lock.doc.fill")
            }

            // OAuth Scope Management
            Section {
                Picker("Grant Type", selection: $oauthGrantType) {
                    ForEach(OAuthGrantType.allCases, id: \.self) { grant in
                        Text(grant.rawValue).tag(grant)
                    }
                }
                .pickerStyle(.menu)

                if oauthScopes.isEmpty {
                    Text("No OAuth scopes configured.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(oauthScopes) { scope in
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                            Text(scope.name).font(.caption.monospaced())
                            Spacer()
                            Text(scope.isRequired ? "Required" : "Optional")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(scope.isRequired ? .red : .secondary)
                        }
                    }
                    .onDelete { oauthScopes.remove(atOffsets: $0) }
                }

                HStack {
                    TextField("Scope name (e.g. read:user)", text: $newOAuthScope)
                        .textInputAutocapitalization(.never).font(.caption.monospaced())
                    Button("Add") {
                        oauthScopes.append(OAuthScopeEntry(name: newOAuthScope))
                        newOAuthScope = ""
                    }.disabled(newOAuthScope.isEmpty)
                }
            } header: {
                Label("OAuth Scopes", systemImage: "person.badge.key.fill")
            }

            // CORS Configuration
            Section {
                Toggle(isOn: $corsEnabled) {
                    Label("Enable CORS", systemImage: "globe.badge.chevron.backward")
                }

                if corsEnabled {
                    Toggle(isOn: $corsAllowCredentials) {
                        Label("Allow Credentials", systemImage: "key.fill")
                    }

                    Stepper(value: $corsMaxAge, in: 0...86400, step: 300) {
                        HStack {
                            Label("Preflight Cache", systemImage: "clock")
                            Spacer()
                            Text("\(corsMaxAge)s").bold().font(.caption)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Allowed Methods").font(.caption.bold()).foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(httpMethods, id: \.self) { method in
                                    Button {
                                        if corsAllowedMethods.contains(method) { corsAllowedMethods.remove(method) }
                                        else { corsAllowedMethods.insert(method) }
                                    } label: {
                                        Text(method)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(corsAllowedMethods.contains(method) ? Color.blue : Color(.tertiarySystemBackground), in: Capsule())
                                            .foregroundStyle(corsAllowedMethods.contains(method) ? .white : .primary)
                                    }
                                }
                            }
                        }
                    }

                    if corsAllowedOrigins.isEmpty {
                        Text("No allowed origins (all blocked).").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(corsAllowedOrigins, id: \.self) { origin in
                            HStack {
                                Text(origin).font(.caption.monospaced())
                                Spacer()
                                Button { corsAllowedOrigins.removeAll { $0 == origin } } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                                }
                            }
                        }
                    }

                    HStack {
                        TextField("Origin (e.g. https://example.com)", text: $newCORSOrigin)
                            .textInputAutocapitalization(.never).font(.caption.monospaced())
                        Button("Add") {
                            corsAllowedOrigins.append(newCORSOrigin); newCORSOrigin = ""
                        }.disabled(newCORSOrigin.isEmpty)
                    }
                }
            } header: {
                Label("CORS Configuration", systemImage: "arrow.left.arrow.right.circle")
            } footer: {
                Text("Cross-Origin Resource Sharing controls which domains can access your plugin's endpoints.")
            }

            // Content Filtering
            Section {
                Toggle(isOn: $contentFilteringEnabled) {
                    Label("Content Filtering", systemImage: "line.3.horizontal.decrease.circle")
                }

                if contentFilteringEnabled {
                    Toggle(isOn: $blockMaliciousPayloads) {
                        Label("Block Malicious Payloads", systemImage: "xmark.shield.fill")
                    }
                    Toggle(isOn: $sanitizeHTML) {
                        Label("Sanitize HTML Input", systemImage: "chevron.left.forwardslash.chevron.right")
                    }

                    Stepper(value: $maxPayloadSizeKB, in: 64...10240, step: 64) {
                        HStack {
                            Label("Max Payload Size", systemImage: "doc.fill")
                            Spacer()
                            Text("\(maxPayloadSizeKB) KB").bold().font(.caption)
                        }
                    }

                    ForEach(contentFilterRules) { rule in
                        HStack {
                            Image(systemName: rule.action == .block ? "xmark.circle.fill" : "eye.slash.fill")
                                .foregroundStyle(rule.action == .block ? .red : .orange)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rule.pattern).font(.caption.monospaced())
                                Text(rule.action.rawValue).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { contentFilterRules.remove(atOffsets: $0) }
                }
            } header: {
                Label("Content Filtering", systemImage: "doc.text.magnifyingglass")
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

            // Access Control Lists
            Section {
                if aclEntries.isEmpty {
                    Text("No ACL entries. Default policy applies.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(aclEntries) { entry in
                        HStack {
                            Image(systemName: entry.permission.icon)
                                .foregroundStyle(entry.permission.color)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.principal).font(.caption.bold())
                                Text(entry.permission.rawValue).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.effect.rawValue)
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(entry.effect == .allow ? Color.green.opacity(0.12) : Color.red.opacity(0.12), in: Capsule())
                                .foregroundStyle(entry.effect == .allow ? .green : .red)
                        }
                    }
                    .onDelete { aclEntries.remove(atOffsets: $0) }
                }

                HStack {
                    TextField("Principal (e.g. user:admin)", text: $newACLPrincipal)
                        .textInputAutocapitalization(.never).font(.caption.monospaced())
                    Picker("", selection: $newACLPermission) {
                        ForEach(ACLPermission.allCases, id: \.self) { p in Text(p.rawValue).tag(p) }
                    }
                    .pickerStyle(.menu).labelsHidden().controlSize(.small)
                    Button("Add") {
                        aclEntries.append(ACLEntry(principal: newACLPrincipal, permission: newACLPermission))
                        newACLPrincipal = ""
                    }.disabled(newACLPrincipal.isEmpty)
                }
            } header: {
                Label("Access Control Lists", systemImage: "person.2.badge.gearshape")
            }

            // Vulnerability Scanning
            Section {
                Toggle(isOn: $autoScanEnabled) {
                    Label("Auto Vulnerability Scan", systemImage: "magnifyingglass.circle.fill")
                }

                if autoScanEnabled {
                    Stepper(value: $scanFrequencyDays, in: 1...30) {
                        HStack {
                            Label("Scan Frequency", systemImage: "calendar")
                            Spacer()
                            Text("Every \(scanFrequencyDays) day(s)").bold().font(.caption)
                        }
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Scan").font(.caption.bold())
                        Text(lastScanDate?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Vulnerabilities").font(.caption.bold())
                        Text("\(vulnerabilityCount)")
                            .font(.caption.bold())
                            .foregroundStyle(vulnerabilityCount == 0 ? .green : .red)
                    }
                }

                Button("Run Scan Now", systemImage: "play.fill") {
                    lastScanDate = Date()
                    vulnerabilityCount = 0
                }
                .font(.caption)
            } header: {
                Label("Vulnerability Scanning", systemImage: "shield.lefthalf.filled.badge.checkmark")
            }

            // Breach Notification
            Section {
                Toggle(isOn: $breachNotificationEnabled) {
                    Label("Breach Notifications", systemImage: "exclamationmark.shield.fill")
                }

                if breachNotificationEnabled {
                    Toggle(isOn: $breachAutoLockdown) {
                        Label("Auto-Lockdown on Breach", systemImage: "lock.open.rotation")
                    }

                    Stepper(value: $breachNotificationDelay, in: 0...24) {
                        HStack {
                            Label("Notification Delay", systemImage: "clock.badge.exclamationmark")
                            Spacer()
                            Text(breachNotificationDelay == 0 ? "Immediate" : "\(breachNotificationDelay)h").bold().font(.caption)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notification Channels").font(.caption.bold()).foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ForEach(["email", "sms", "slack", "webhook"], id: \.self) { channel in
                                Button {
                                    if breachNotificationChannels.contains(channel) { breachNotificationChannels.remove(channel) }
                                    else { breachNotificationChannels.insert(channel) }
                                } label: {
                                    Text(channel.capitalized)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(breachNotificationChannels.contains(channel) ? Color.red : Color(.tertiarySystemBackground), in: Capsule())
                                        .foregroundStyle(breachNotificationChannels.contains(channel) ? .white : .primary)
                                }
                            }
                        }
                    }
                }
            } header: {
                Label("Breach Response", systemImage: "bell.badge.fill")
            } footer: {
                Text("Automated breach response helps minimize damage from security incidents.")
            }

            // Incident Playbook
            Section {
                if playbookSteps.isEmpty {
                    Text("No incident playbook steps defined.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(playbookSteps.enumerated()), id: \.element.id) { index, step in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .frame(width: 24, height: 24)
                                .background(step.priority.color.opacity(0.12), in: Circle())
                                .foregroundStyle(step.priority.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title).font(.caption.bold())
                                Text(step.description).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { playbookSteps.remove(atOffsets: $0) }
                }

                Button("Add Playbook Step", systemImage: "plus.circle.fill") {
                    playbookSteps.append(IncidentPlaybookStep(title: "Step \(playbookSteps.count + 1)", description: "Describe the action...", priority: .medium))
                }
                .font(.caption)
            } header: {
                Label("Incident Playbook", systemImage: "book.fill")
            } footer: {
                Text("Define step-by-step response procedures for security incidents.")
            }

            // Security Training
            Section {
                HStack {
                    Image(systemName: securityTrainingCompleted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(securityTrainingCompleted ? .green : .orange)
                    Text(securityTrainingCompleted ? "Training Complete" : "Training Required")
                        .font(.caption.bold())
                        .foregroundStyle(securityTrainingCompleted ? .green : .orange)
                    Spacer()
                    if let date = trainingCompletionDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Required Modules").font(.caption.bold()).foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 6) {
                        ForEach(trainingModules, id: \.self) { module in
                            Button {
                                if requiredTrainingModules.contains(module) { requiredTrainingModules.remove(module) }
                                else { requiredTrainingModules.insert(module) }
                            } label: {
                                Text(module)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(requiredTrainingModules.contains(module) ? Color.green : Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
                                    .foregroundStyle(requiredTrainingModules.contains(module) ? .white : .primary)
                            }
                        }
                    }
                }

                Button("Mark Training Complete") {
                    securityTrainingCompleted = true
                    trainingCompletionDate = Date()
                }
                .font(.caption)
                .disabled(securityTrainingCompleted)
            } header: {
                Label("Security Training", systemImage: "graduationcap.fill")
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

            // Security Actions
            Section {
                Button { showingSecurityReport = true } label: {
                    Label("Generate Security Report", systemImage: "doc.text.fill").frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.bordered)

                Button { showingAuditLog = true } label: {
                    Label("View Audit Log", systemImage: "list.bullet.rectangle").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    plugin.apiKey = nil
                    certificates.removeAll()
                    oauthScopes.removeAll()
                    aclEntries.removeAll()
                } label: {
                    Label("Reset All Security Settings", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } header: {
                Label("Security Actions", systemImage: "bolt.shield.fill")
            }
        }
        .navigationTitle("Security Scopes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { dismiss() }.bold()
            }
        }
        .sheet(isPresented: $showingSecurityReport) {
            NavigationStack {
                SecurityReportSheet(
                    score: securityScore,
                    grade: securityGrade,
                    encryptionAlgorithm: encryptionAlgorithm,
                    mfaRequired: mfaRequired,
                    complianceCount: complianceFrameworks.count,
                    certCount: certificates.count,
                    aclCount: aclEntries.count,
                    hasKey: plugin.apiKey != nil,
                    trainingComplete: securityTrainingCompleted
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAuditLog) {
            NavigationStack {
                SecurityAuditLogSheet()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Security Score

    private var securityScore: Int {
        var score = 0
        if plugin.apiKey != nil { score += 15 }
        if encryptionRequired { score += 10 }
        if mfaRequired { score += 10 }
        if auditLoggingEnabled { score += 8 }
        if dataMinimizationEnabled { score += 5 }
        if safetyChecksEnabled { score += 5 }
        if webhookVerification { score += 5 }
        if enableAutoRotation { score += 7 }
        if geoRestrictionEnabled { score += 5 }
        if !complianceFrameworks.isEmpty { score += 8 }
        if !incidentContacts.isEmpty { score += 5 }
        if enableHSTS { score += 5 }
        if certPinningEnabled { score += 5 }
        if breachNotificationEnabled { score += 4 }
        if securityTrainingCompleted { score += 3 }
        return min(score, 100)
    }

    private var securityGrade: String {
        switch securityScore {
        case 90...100: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        case 50..<60: return "D"
        default: return "F"
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

// MARK: - Security Score Header

private struct SecurityScoreHeader: View {
    let score: Int
    let grade: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Text("/ 100")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Security Grade").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(grade)
                        .font(.title2.bold())
                        .foregroundStyle(scoreColor)
                }
                Text(scoreDescription).font(.caption2).foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: score >= 70 ? "shield.checkered" : "exclamationmark.shield")
                        .foregroundStyle(scoreColor).font(.caption)
                    Text(score >= 70 ? "Good Standing" : "Needs Attention")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(scoreColor)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    private var scoreDescription: String {
        switch score {
        case 90...100: return "Excellent security posture. All critical controls in place."
        case 80..<90: return "Strong security. Minor improvements available."
        case 70..<80: return "Good baseline. Some controls should be enabled."
        case 60..<70: return "Moderate risk. Several controls need attention."
        default: return "High risk. Critical security controls are missing."
        }
    }
}

// MARK: - Key Strength Indicator

private struct SecurityKeyStrengthIndicator: View {
    let key: String

    private var strength: Int {
        var s = 0
        if key.count >= 30 { s += 1 }
        if key.contains("-") { s += 1 }
        if key.range(of: "[0-9]", options: .regularExpression) != nil { s += 1 }
        if key.range(of: "[a-z]", options: .regularExpression) != nil { s += 1 }
        return s
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(i < strength ? strengthColor : Color.secondary.opacity(0.2))
                    .frame(width: 14, height: 3)
                    .clipShape(Capsule())
            }
            Text(strengthLabel)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(strengthColor)
        }
    }

    private var strengthColor: Color {
        switch strength {
        case 4: return .green
        case 3: return .blue
        case 2: return .orange
        default: return .red
        }
    }

    private var strengthLabel: String {
        switch strength {
        case 4: return "Strong"
        case 3: return "Good"
        case 2: return "Fair"
        default: return "Weak"
        }
    }
}

// MARK: - Security Report Sheet

private struct SecurityReportSheet: View {
    let score: Int
    let grade: String
    let encryptionAlgorithm: String
    let mfaRequired: Bool
    let complianceCount: Int
    let certCount: Int
    let aclCount: Int
    let hasKey: Bool
    let trainingComplete: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                SecurityScoreHeader(score: score, grade: grade)
            }
            .listRowBackground(Color.clear)

            Section("Security Checklist") {
                SecurityCheckRow(label: "API Key Configured", passed: hasKey)
                SecurityCheckRow(label: "MFA Required", passed: mfaRequired)
                SecurityCheckRow(label: "Compliance Frameworks", passed: complianceCount > 0)
                SecurityCheckRow(label: "Certificates", passed: certCount > 0)
                SecurityCheckRow(label: "Access Control Lists", passed: aclCount > 0)
                SecurityCheckRow(label: "Security Training", passed: trainingComplete)
            }

            Section("Configuration") {
                LabeledContent("Encryption", value: encryptionAlgorithm)
                LabeledContent("Compliance Frameworks", value: "\(complianceCount)")
                LabeledContent("Certificates", value: "\(certCount)")
                LabeledContent("ACL Entries", value: "\(aclCount)")
            }
        }
        .navigationTitle("Security Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}

private struct SecurityCheckRow: View {
    let label: String
    let passed: Bool

    var body: some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(passed ? .green : .red)
            Text(label).font(.subheadline)
            Spacer()
            Text(passed ? "Pass" : "Fail")
                .font(.caption.bold())
                .foregroundStyle(passed ? .green : .red)
        }
    }
}

// MARK: - Audit Log Sheet

private struct SecurityAuditLogSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let sampleEntries = [
        "Key generated for region US",
        "MFA requirement enabled",
        "Encryption algorithm changed to AES-256-GCM",
        "Geo-restriction enabled",
        "Compliance framework SOC 2 added",
        "Incident contact added",
        "Session timeout updated to 60 min",
        "Webhook verification enabled",
    ]

    var body: some View {
        List {
            Section("Audit Trail") {
                ForEach(Array(sampleEntries.enumerated()), id: \.offset) { index, entry in
                    HStack {
                        Circle().fill(Color.blue.opacity(0.3)).frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry).font(.caption)
                            Text(Date().addingTimeInterval(TimeInterval(-index * 3600)).formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Audit Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}

// MARK: - Supporting Types

struct SecurityCertificate: Identifiable {
    let id = UUID()
    var domain: String
    var expiryDate: Date
    var isExpired: Bool { expiryDate < Date() }
}

struct OAuthScopeEntry: Identifiable {
    let id = UUID()
    var name: String
    var isRequired: Bool = true
}

enum OAuthGrantType: String, CaseIterable {
    case authorizationCode = "Authorization Code"
    case clientCredentials = "Client Credentials"
    case deviceCode = "Device Code"
    case pkce = "PKCE"
}

enum DataClassification: String, CaseIterable {
    case publicData = "Public"
    case `internal` = "Internal"
    case confidential = "Confidential"
    case restricted = "Restricted"

    var color: Color {
        switch self {
        case .publicData: return .green
        case .internal: return .blue
        case .confidential: return .orange
        case .restricted: return .red
        }
    }
}

struct ContentFilterRule: Identifiable {
    let id = UUID()
    var pattern: String
    var action: FilterAction
}

enum FilterAction: String, CaseIterable {
    case block = "Block"
    case sanitize = "Sanitize"
    case log = "Log Only"
}

struct ACLEntry: Identifiable {
    let id = UUID()
    var principal: String
    var permission: ACLPermission
    var effect: ACLEffect = .allow
}

enum ACLPermission: String, CaseIterable {
    case read = "Read"
    case write = "Write"
    case execute = "Execute"
    case admin = "Admin"

    var icon: String {
        switch self {
        case .read: return "eye"
        case .write: return "pencil"
        case .execute: return "play"
        case .admin: return "crown"
        }
    }

    var color: Color {
        switch self {
        case .read: return .blue
        case .write: return .orange
        case .execute: return .green
        case .admin: return .red
        }
    }
}

enum ACLEffect: String, CaseIterable {
    case allow = "Allow"
    case deny = "Deny"
}

enum TLSVersion: String, CaseIterable {
    case tls10 = "TLS 1.0"
    case tls11 = "TLS 1.1"
    case tls12 = "TLS 1.2"
    case tls13 = "TLS 1.3"
}

struct IncidentPlaybookStep: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var priority: PlaybookPriority
}

enum PlaybookPriority: String, CaseIterable {
    case low, medium, high, critical

    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct SecretRotationEntry: Identifiable {
    let id = UUID()
    let date = Date()
    var region: String
    var wasAutomatic: Bool
}
