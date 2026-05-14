

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

    var body: some View {
        Form {
            if let conn = connector {
                Section {
                    HStack(spacing: 0) {
                        DetailMetricPill(label: "Auth", value: conn.authConfig.type.rawValue.capitalized, color: conn.authConfig.type == .none ? .red : .sdkSuccess)
                        DetailMetricPill(label: "Rate Limit", value: "\(rateLimit)/m", color: .blue)
                        DetailMetricPill(label: "Scopes", value: "\(requestedScopes.count)", color: .purple)
                    }.padding(.vertical, 8)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            }

            AccessControlSection(tls: $enforceTLS, publicAccess: $allowPublicAccess, rateLimit: $rateLimit)

            IPWhitelistSection(enabled: $enableIPWhitelist, ips: $whitelistedIPs, newIP: $newIPAddress)

            Section("Token Policy") {
                Stepper("\(tokenExpiryHours) Hours", value: $tokenExpiryHours, in: 1...720).font(.subheadline)
                Toggle("Auto-Refresh", isOn: $autoRefreshTokens)

                Button("Rotate Secrets Now") {
                    rotateSecrets()
                }
                .font(.caption)
            }

            CORSConfigSection(enabled: $enableCORS, origins: $allowedOrigins, newOrigin: $newOrigin)

            Section("Webhook Integrity") {
                Toggle("Sign Payloads", isOn: $enableWebhookSignatures)
                if enableWebhookSignatures {
                    HStack { SecureField("Signing Secret", text: $webhookSecret).font(.caption.monospaced()); Button { webhookSecret = (0..<32).map { _ in String("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()!) }.joined() } label: { Image(systemName: "arrow.clockwise") } }
                }
            }

            ScopeManagementSection(scopes: $requestedScopes, newScope: $newScopeText)

            Section("Compliance") {
                ComplianceRow(label: "Data Residency", value: "Local")
                ComplianceRow(label: "Encryption", value: "AES-256")
                ComplianceRow(label: "Audit Logs", value: "Enabled", color: .sdkSuccess)
            }

            Section {
                Button("Apply Security Policy") { showingSaveAlert = true }.frame(maxWidth: .infinity).bold().buttonStyle(.borderedProminent)
                Button("Reset Defaults", role: .destructive) { showingResetAlert = true }.frame(maxWidth: .infinity)
            }.listRowBackground(Color.clear)
        }
        .navigationTitle("Security").navigationBarTitleDisplayMode(.inline)
        .alert("Policy Applied", isPresented: $showingSaveAlert) { Button("OK") {} }
        .alert("Reset Settings?", isPresented: $showingResetAlert) { Button("Cancel", role: .cancel) {}; Button("Reset", role: .destructive) { resetToDefaults() } }
    }

    private func rotateSecrets() {
        // Feature 4: Secret Rotation
        guard var conn = connector else { return }
        if conn.authConfig.type == .apiKey {
            let newKey = "tk_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            conn.authConfig.credentials["apiKey"] = newKey
            manager.updateConnector(conn)
            connector = conn
            SDKLogStore.shared.log("Rotating secrets for \(conn.name)", source: "SecurityView", level: .info)
        }
    }

    private func resetToDefaults() { rateLimit = 60; enforceTLS = true; allowPublicAccess = false; enableIPWhitelist = false; whitelistedIPs = []; tokenExpiryHours = 24; autoRefreshTokens = true; enableCORS = true; allowedOrigins = ["*"]; enableWebhookSignatures = true; webhookSecret = ""; requestedScopes = ["api.read", "api.write"] }
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
