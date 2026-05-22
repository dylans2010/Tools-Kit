

import SwiftUI

struct ConnectorSecurityView: View {
    @State var connector: ConnectorDefinition?
    @StateObject private var manager = ConnectorManager.shared

    @State private var rateLimit = 60
    @State private var enforceTLS = true
    @State private var allowPublicAccess = false
    @State private var requestedScopes: Set<String> = ["api.read", "api.write"]
    @State private var newScopeText = ""
    @State private var enableIPWhitelist = false
    @State private var whitelistedIPs: [String] = []
    @State private var newIPAddress = ""
    @State private var tokenExpiryHours = 24
    @State private var autoRefreshTokens = true
    @State private var enableCORS = true
    @State private var allowedOrigins: [String] = ["*"]
    @State private var newOrigin = ""
    @State private var enableWebhookSignatures = true
    @State private var webhookSecret = ""
    @State private var showingSaveAlert = false
    @State private var showingResetAlert = false
    @State private var showingAuditLog = false
    @State private var auditEntries: [SecurityAuditEntry] = []
    @State private var enableCertPinning = false
    @State private var pinnedCertHashes: [String] = []
    @State private var newCertHash = ""
    @State private var enableMTLS = false
    @State private var clientCertRequired = false
    @State private var showingSecurityScan = false
    @State private var securityScore: Int = 0
    @State private var securityIssues: [SecurityIssue] = []
    @State private var enableRequestSigning = false
    @State private var signingAlgorithm: SigningAlgorithm = .hmacSHA256
    @State private var enableAuditLogging = true
    @State private var showingExportPolicy = false

    var body: some View {
        Form {
            if let conn = connector {
                Section {
                    HStack(spacing: 0) {
                        DetailMetricPill(label: "Auth", value: conn.authConfig.type.rawValue.capitalized, color: conn.authConfig.type == .none ? .red : .sdkSuccess)
                        DetailMetricPill(label: "Rate Limit", value: "\(rateLimit)/m", color: .blue)
                        DetailMetricPill(label: "Scopes", value: "\(requestedScopes.count)", color: .purple)
                        DetailMetricPill(label: "Score", value: "\(securityScore)", color: securityScore >= 80 ? .green : securityScore >= 50 ? .orange : .red)
                    }.padding(.vertical, 8)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            }

            AccessControlSection(tls: $enforceTLS, publicAccess: $allowPublicAccess, rateLimit: $rateLimit)

            IPWhitelistSection(enabled: $enableIPWhitelist, ips: $whitelistedIPs, newIP: $newIPAddress)

            Section("Token Policy") {
                Stepper("\(tokenExpiryHours) Hours", value: $tokenExpiryHours, in: 1...720).font(.subheadline)
                Toggle("Auto-Refresh", isOn: $autoRefreshTokens)
            }

            certPinningSection

            mtlsSection

            requestSigningSection

            CORSConfigSection(enabled: $enableCORS, origins: $allowedOrigins, newOrigin: $newOrigin)

            Section("Webhook Integrity") {
                Toggle("Sign Payloads", isOn: $enableWebhookSignatures)
                if enableWebhookSignatures {
                    HStack { SecureField("Signing Secret", text: $webhookSecret).font(.caption.monospaced()); Button { webhookSecret = (0..<32).map { _ in String("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()!) }.joined() } label: { Image(systemName: "arrow.clockwise") } }
                }
            }

            ScopeManagementSection(scopes: $requestedScopes, newScope: $newScopeText)

            auditSection

            Section("Compliance") {
                ComplianceRow(label: "Data Residency", value: "Local")
                ComplianceRow(label: "Encryption", value: "AES-256")
                ComplianceRow(label: "Audit Logs", value: enableAuditLogging ? "Enabled" : "Disabled", color: enableAuditLogging ? .sdkSuccess : .red)
                ComplianceRow(label: "mTLS", value: enableMTLS ? "Active" : "Inactive", color: enableMTLS ? .sdkSuccess : .secondary)
                ComplianceRow(label: "Cert Pinning", value: enableCertPinning ? "Active" : "Inactive", color: enableCertPinning ? .sdkSuccess : .secondary)
                ComplianceRow(label: "Request Signing", value: enableRequestSigning ? signingAlgorithm.rawValue : "Disabled", color: enableRequestSigning ? .sdkSuccess : .secondary)
            }

            Section {
                Button("Apply Security Policy") { applyPolicy(); showingSaveAlert = true }.frame(maxWidth: .infinity).bold().buttonStyle(.borderedProminent)
                Button("Run Security Scan") { runSecurityScan(); showingSecurityScan = true }.frame(maxWidth: .infinity)
                Button("Reset Defaults", role: .destructive) { showingResetAlert = true }.frame(maxWidth: .infinity)
            }.listRowBackground(Color.clear)
        }
        .navigationTitle("Security").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingAuditLog = true } label: { Label("Audit Log", systemImage: "list.clipboard") }
                    Button { showingExportPolicy = true } label: { Label("Export Policy", systemImage: "square.and.arrow.up") }
                    Button { runSecurityScan(); showingSecurityScan = true } label: { Label("Security Scan", systemImage: "shield.checkered") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .onAppear { runSecurityScan() }
        .alert("Policy Applied", isPresented: $showingSaveAlert) { Button("OK") {} }
        .alert("Reset Settings?", isPresented: $showingResetAlert) { Button("Cancel", role: .cancel) {}; Button("Reset", role: .destructive) { resetToDefaults() } }
        .sheet(isPresented: $showingAuditLog) {
            NavigationStack { auditLogSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSecurityScan) {
            NavigationStack { securityScanSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExportPolicy) {
            NavigationStack { exportPolicySheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Certificate Pinning

    private var certPinningSection: some View {
        Section("Certificate Pinning") {
            Toggle("Enable Certificate Pinning", isOn: $enableCertPinning)
            if enableCertPinning {
                ForEach(pinnedCertHashes, id: \.self) { hash in
                    HStack {
                        Text(hash).font(.caption.monospaced()).lineLimit(1)
                        Spacer()
                        Button { pinnedCertHashes.removeAll { $0 == hash } } label: { Image(systemName: "minus.circle.fill").foregroundStyle(.red) }
                    }
                }
                HStack {
                    TextField("SHA-256 Hash", text: $newCertHash)
                        .font(.caption.monospaced())
                        .textInputAutocapitalization(.never)
                    Button {
                        pinnedCertHashes.append(newCertHash)
                        newCertHash = ""
                    } label: { Image(systemName: "plus.circle.fill") }
                    .disabled(newCertHash.isEmpty)
                }
            }
        }
    }

    // MARK: - mTLS

    private var mtlsSection: some View {
        Section("Mutual TLS") {
            Toggle("Enable mTLS", isOn: $enableMTLS)
            if enableMTLS {
                Toggle("Require Client Certificate", isOn: $clientCertRequired)
                LabeledContent("Verification", value: clientCertRequired ? "Strict" : "Optional")
                    .font(.caption)
            }
        }
    }

    // MARK: - Request Signing

    private var requestSigningSection: some View {
        Section("Request Signing") {
            Toggle("Enable Request Signing", isOn: $enableRequestSigning)
            if enableRequestSigning {
                Picker("Algorithm", selection: $signingAlgorithm) {
                    ForEach(SigningAlgorithm.allCases, id: \.self) { algo in
                        Text(algo.rawValue).tag(algo)
                    }
                }
                LabeledContent("Headers Signed") {
                    Text("Authorization, Date, Content-Type")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Audit Section

    private var auditSection: some View {
        Section("Audit Logging") {
            Toggle("Enable Audit Logging", isOn: $enableAuditLogging)
            if !auditEntries.isEmpty {
                LabeledContent("Recent Events", value: "\(auditEntries.count)")
                Button { showingAuditLog = true } label: {
                    Label("View Audit Log", systemImage: "list.clipboard")
                }
                .font(.caption)
            }
        }
    }

    // MARK: - Sheets

    private var auditLogSheet: some View {
        List {
            if auditEntries.isEmpty {
                ContentUnavailableView("No Audit Entries", systemImage: "list.clipboard", description: Text("Security events will be logged here."))
            } else {
                ForEach(auditEntries) { entry in
                    HStack {
                        Image(systemName: entry.icon)
                            .foregroundStyle(entry.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.action).font(.subheadline)
                            Text(entry.detail).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .navigationTitle("Audit Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var securityScanSheet: some View {
        List {
            Section("Security Score") {
                HStack {
                    Text("\(securityScore)").font(.system(size: 48, weight: .bold)).foregroundStyle(securityScore >= 80 ? .green : securityScore >= 50 ? .orange : .red)
                    VStack(alignment: .leading) {
                        Text(securityScore >= 80 ? "Good" : securityScore >= 50 ? "Fair" : "Needs Improvement")
                            .font(.headline)
                        Text("\(securityIssues.count) issue(s) found")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if !securityIssues.isEmpty {
                Section("Issues") {
                    ForEach(securityIssues) { issue in
                        HStack {
                            Image(systemName: issue.severity == .critical ? "exclamationmark.octagon.fill" : issue.severity == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                .foregroundStyle(issue.severity == .critical ? .red : issue.severity == .warning ? .orange : .blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(issue.title).font(.subheadline.bold())
                                Text(issue.recommendation).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Security Scan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var exportPolicySheet: some View {
        Form {
            Section("Security Policy Summary") {
                LabeledContent("TLS", value: enforceTLS ? "Enforced" : "Disabled")
                LabeledContent("Public Access", value: allowPublicAccess ? "Allowed" : "Denied")
                LabeledContent("Rate Limit", value: "\(rateLimit)/min")
                LabeledContent("IP Whitelist", value: enableIPWhitelist ? "\(whitelistedIPs.count) IPs" : "Disabled")
                LabeledContent("Token Expiry", value: "\(tokenExpiryHours)h")
                LabeledContent("CORS", value: enableCORS ? "Enabled" : "Disabled")
                LabeledContent("mTLS", value: enableMTLS ? "Enabled" : "Disabled")
                LabeledContent("Cert Pinning", value: enableCertPinning ? "\(pinnedCertHashes.count) certs" : "Disabled")
                LabeledContent("Scopes", value: "\(requestedScopes.count)")
            }
            Section {
                Button("Copy Policy to Clipboard") {
                    UIPasteboard.general.string = buildPolicyExport()
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Export Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func applyPolicy() {
        let entry = SecurityAuditEntry(action: "Policy Applied", detail: "Security policy updated with \(requestedScopes.count) scopes, rate limit \(rateLimit)/min", icon: "checkmark.shield.fill", color: .green, timestamp: Date())
        auditEntries.insert(entry, at: 0)
    }

    private func runSecurityScan() {
        var score = 100
        var issues: [SecurityIssue] = []
        if !enforceTLS { score -= 20; issues.append(SecurityIssue(title: "TLS Not Enforced", recommendation: "Enable TLS 1.3+ for secure communication", severity: .critical)) }
        if allowPublicAccess { score -= 15; issues.append(SecurityIssue(title: "Public Access Enabled", recommendation: "Restrict access to authenticated users only", severity: .warning)) }
        if !enableIPWhitelist { score -= 5; issues.append(SecurityIssue(title: "No IP Whitelist", recommendation: "Consider restricting access by IP address", severity: .info)) }
        if tokenExpiryHours > 72 { score -= 10; issues.append(SecurityIssue(title: "Long Token Expiry", recommendation: "Reduce token expiry to 24h or less", severity: .warning)) }
        if !enableCertPinning { score -= 5; issues.append(SecurityIssue(title: "No Certificate Pinning", recommendation: "Pin server certificates to prevent MITM attacks", severity: .info)) }
        if !enableMTLS { score -= 5; issues.append(SecurityIssue(title: "mTLS Disabled", recommendation: "Enable mutual TLS for enhanced authentication", severity: .info)) }
        if allowedOrigins.contains("*") && enableCORS { score -= 10; issues.append(SecurityIssue(title: "Wildcard CORS Origin", recommendation: "Restrict CORS to specific origins", severity: .warning)) }
        if webhookSecret.isEmpty && enableWebhookSignatures { score -= 10; issues.append(SecurityIssue(title: "Empty Webhook Secret", recommendation: "Generate a strong webhook signing secret", severity: .critical)) }
        securityScore = max(score, 0)
        securityIssues = issues
    }

    private func resetToDefaults() { rateLimit = 60; enforceTLS = true; allowPublicAccess = false; enableIPWhitelist = false; whitelistedIPs = []; tokenExpiryHours = 24; autoRefreshTokens = true; enableCORS = true; allowedOrigins = ["*"]; enableWebhookSignatures = true; webhookSecret = ""; requestedScopes = ["api.read", "api.write"]; enableCertPinning = false; pinnedCertHashes = []; enableMTLS = false; enableRequestSigning = false }

    private func buildPolicyExport() -> String {
        var lines: [String] = ["=== Security Policy Export ===", "Generated: \(Date().formatted())", ""]
        lines.append("TLS: \(enforceTLS ? "Enforced" : "Disabled")")
        lines.append("Public Access: \(allowPublicAccess ? "Allowed" : "Denied")")
        lines.append("Rate Limit: \(rateLimit)/min")
        lines.append("Token Expiry: \(tokenExpiryHours)h, Auto-Refresh: \(autoRefreshTokens)")
        lines.append("CORS: \(enableCORS ? "Enabled (\(allowedOrigins.joined(separator: ", ")))" : "Disabled")")
        lines.append("mTLS: \(enableMTLS ? "Enabled" : "Disabled")")
        lines.append("Cert Pinning: \(enableCertPinning ? "\(pinnedCertHashes.count) certs" : "Disabled")")
        lines.append("Request Signing: \(enableRequestSigning ? signingAlgorithm.rawValue : "Disabled")")
        lines.append("Scopes: \(requestedScopes.sorted().joined(separator: ", "))")
        lines.append("Security Score: \(securityScore)/100")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Private Sections

private struct AccessControlSection: View {
    @Binding var tls: Bool; @Binding var publicAccess: Bool; @Binding var rateLimit: Int
    var body: some View {
        Section("Access Control") {
            Toggle("Enforce TLS 1.3+", isOn: $tls)
            Toggle("Public Access", isOn: $publicAccess)
            if publicAccess { Label("Unauthenticated requests allowed.", systemImage: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.orange) }
            Stepper("\(rateLimit) requests / min", value: $rateLimit, in: 1...1000).font(.subheadline)
        }
    }
}

private struct IPWhitelistSection: View {
    @Binding var enabled: Bool; @Binding var ips: [String]; @Binding var newIP: String
    var body: some View {
        Section("IP Whitelist") {
            Toggle("Filter by Address", isOn: $enabled)
            if enabled {
                ForEach(ips, id: \.self) { ip in HStack { Text(ip).font(.caption.monospaced()); Spacer(); Button { ips.removeAll { $0 == ip } } label: { Image(systemName: "minus.circle.fill").foregroundStyle(.red) } } }
                HStack { TextField("IP/CIDR", text: $newIP).font(.caption.monospaced()); Button { ips.append(newIP); newIP = "" } label: { Image(systemName: "plus.circle.fill") }.disabled(newIP.isEmpty) }
            }
        }
    }
}

private struct CORSConfigSection: View {
    @Binding var enabled: Bool; @Binding var origins: [String]; @Binding var newOrigin: String
    var body: some View {
        Section("CORS Policy") {
            Toggle("Enable CORS", isOn: $enabled)
            if enabled {
                ForEach(origins, id: \.self) { origin in HStack { Text(origin).font(.caption.monospaced()); Spacer(); if origin != "*" { Button { origins.removeAll { $0 == origin } } label: { Image(systemName: "minus.circle.fill").foregroundStyle(.red) } } } }
                HStack { TextField("Origin URL", text: $newOrigin).font(.caption.monospaced()); Button { origins.append(newOrigin); newOrigin = "" } label: { Image(systemName: "plus.circle.fill") }.disabled(newOrigin.isEmpty) }
            }
        }
    }
}

private struct ScopeManagementSection: View {
    @Binding var scopes: Set<String>; @Binding var newScope: String
    var body: some View {
        Section("Required Scopes") {
            ForEach(Array(scopes).sorted(), id: \.self) { scope in HStack { Label(scope, systemImage: "shield.fill").font(.caption.monospaced()).foregroundStyle(Color.accentColor); Spacer(); Button { scopes.remove(scope) } label: { Image(systemName: "minus.circle.fill").foregroundStyle(.red) } } }
            HStack { TextField("New Scope", text: $newScope).font(.caption.monospaced()); Button { scopes.insert(newScope); newScope = "" } label: { Image(systemName: "plus.circle.fill") }.disabled(newScope.isEmpty) }
        }
    }
}

private struct ComplianceRow: View {
    let label: String; let value: String; var color: Color = .secondary
    var body: some View { HStack { Text(label).font(.subheadline); Spacer(); Text(value).font(.caption).foregroundStyle(color) } }
}

private struct DetailMetricPill: View {
    let label: String; let value: String; let color: Color
    var body: some View { VStack(spacing: 4) { Text(value).font(.headline).foregroundStyle(color); Text(label).font(.caption2.bold()).foregroundStyle(.secondary) }.frame(maxWidth: .infinity) }
}

// MARK: - Security Models

private struct SecurityAuditEntry: Identifiable {
    let id = UUID()
    let action: String
    let detail: String
    let icon: String
    let color: Color
    let timestamp: Date
}

private struct SecurityIssue: Identifiable {
    let id = UUID()
    let title: String
    let recommendation: String
    let severity: IssueSeverity

    enum IssueSeverity: String { case critical, warning, info }
}

private enum SigningAlgorithm: String, CaseIterable {
    case hmacSHA256 = "HMAC-SHA256"
    case hmacSHA512 = "HMAC-SHA512"
    case rsaSHA256 = "RSA-SHA256"
    case ed25519 = "Ed25519"
}
