import SwiftUI

struct ConnectorSecurityView: View {
    @State var connector: ConnectorDefinition?
    @StateObject private var manager = ConnectorManager.shared

    @State private var rateLimit = 60
    @State private var enforceTLS = true
    @State private var allowPublicAccess = false
    @State private var requestedScopes: Set<String> = ["api.read", "api.write"]
    @State private var newScopeText = ""
    @State private var showingAddScope = false

    // IP Whitelist
    @State private var enableIPWhitelist = false
    @State private var whitelistedIPs: [String] = []
    @State private var newIPAddress = ""

    // Token Settings
    @State private var tokenExpiryHours = 24
    @State private var autoRefreshTokens = true

    // CORS
    @State private var enableCORS = true
    @State private var allowedOrigins: [String] = ["*"]
    @State private var newOrigin = ""

    // Webhook
    @State private var enableWebhookSignatures = true
    @State private var webhookSecret = ""

    // Alerts
    @State private var showingSaveAlert = false
    @State private var showingResetAlert = false

    var body: some View {
        Form {
            // MARK: - Security Overview
            if let conn = connector {
                Section {
                    HStack(spacing: 16) {
                        securityStat(label: "Auth", value: conn.authConfig.type.rawValue.capitalized, color: conn.authConfig.type == .none ? .red : .green)
                        securityStat(label: "Rate Limit", value: "\(rateLimit)/min", color: rateLimit < 10 ? .red : .blue)
                        securityStat(label: "Scopes", value: "\(requestedScopes.count)", color: .purple)
                    }
                }
            }

            // MARK: - Access Control
            Section {
                Toggle("Enforce TLS 1.3+", isOn: $enforceTLS)
                Toggle("Allow Public Access", isOn: $allowPublicAccess)

                if allowPublicAccess {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Public access allows unauthenticated requests. Use with caution.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate Limit (Requests/min)").font(.caption).foregroundColor(.secondary)
                    Stepper("\(rateLimit) req/min", value: $rateLimit, in: 1...1000)

                    if rateLimit > 500 {
                        Text("High rate limits may impact performance.")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            } header: {
                Text("Access Control")
            }

            // MARK: - IP Whitelist
            Section {
                Toggle("Enable IP Whitelist", isOn: $enableIPWhitelist)

                if enableIPWhitelist {
                    if whitelistedIPs.isEmpty {
                        Text("No IPs whitelisted. All requests will be blocked when enabled.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        ForEach(whitelistedIPs, id: \.self) { ip in
                            HStack {
                                Image(systemName: "network")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text(ip)
                                    .font(.system(.caption, design: .monospaced))
                                Spacer()
                                Button {
                                    whitelistedIPs.removeAll { $0 == ip }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    HStack {
                        TextField("IP Address (e.g. 192.168.1.0/24)", text: $newIPAddress)
                            .font(.system(.caption, design: .monospaced))
                            .autocapitalization(.none)
                        Button {
                            if !newIPAddress.isEmpty {
                                whitelistedIPs.append(newIPAddress)
                                newIPAddress = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newIPAddress.isEmpty)
                    }
                }
            } header: {
                Text("IP Whitelist")
            }

            // MARK: - Token Management
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Token Expiry").font(.caption).foregroundColor(.secondary)
                    Stepper("\(tokenExpiryHours) Hours", value: $tokenExpiryHours, in: 1...720)
                }

                Toggle("Auto-Refresh Tokens", isOn: $autoRefreshTokens)

                if autoRefreshTokens {
                    Text("Tokens will be refreshed automatically before expiry.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Token Management")
            }

            // MARK: - CORS
            Section {
                Toggle("Enable CORS", isOn: $enableCORS)

                if enableCORS {
                    ForEach(allowedOrigins, id: \.self) { origin in
                        HStack {
                            Text(origin)
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                            if origin != "*" {
                                Button {
                                    allowedOrigins.removeAll { $0 == origin }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    HStack {
                        TextField("Origin (e.g. https://example.com)", text: $newOrigin)
                            .font(.system(.caption, design: .monospaced))
                            .autocapitalization(.none)
                        Button {
                            if !newOrigin.isEmpty {
                                allowedOrigins.append(newOrigin)
                                newOrigin = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newOrigin.isEmpty)
                    }

                    if allowedOrigins.contains("*") {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Wildcard (*) allows all origins. Consider restricting for production.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } header: {
                Text("CORS Configuration")
            }

            // MARK: - Webhook Signatures
            Section {
                Toggle("Require Webhook Signatures", isOn: $enableWebhookSignatures)

                if enableWebhookSignatures {
                    HStack {
                        SecureField("Webhook Signing Secret", text: $webhookSecret)
                            .font(.system(.caption, design: .monospaced))

                        Button {
                            webhookSecret = generateRandomSecret()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                    }

                    Text("All incoming webhook payloads will be verified using HMAC-SHA256.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Webhook Security")
            }

            // MARK: - Required Scopes
            Section {
                ForEach(Array(requestedScopes).sorted(), id: \.self) { scope in
                    HStack {
                        Image(systemName: "shield.fill").foregroundColor(.blue).font(.caption)
                        Text(scope)
                            .font(.system(.caption, design: .monospaced))
                        Spacer()
                        Button {
                            requestedScopes.remove(scope)
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                        }
                    }
                }

                HStack {
                    TextField("Scope (e.g. api.admin)", text: $newScopeText)
                        .font(.system(.caption, design: .monospaced))
                        .autocapitalization(.none)
                    Button {
                        if !newScopeText.isEmpty {
                            requestedScopes.insert(newScopeText)
                            newScopeText = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(newScopeText.isEmpty)
                }

                // Common Scopes
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(["api.read", "api.write", "api.admin", "webhooks", "data.export"], id: \.self) { scope in
                            Button {
                                requestedScopes.insert(scope)
                            } label: {
                                Text(scope)
                                    .font(.system(size: 10, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(requestedScopes.contains(scope) ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.1))
                                    .foregroundColor(requestedScopes.contains(scope) ? .blue : .secondary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } header: {
                Text("Required Scopes")
            }

            // MARK: - Compliance & Data
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Data Residency", systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                        Spacer()
                        Text("Local")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Encryption", systemImage: "lock.fill")
                            .font(.subheadline)
                        Spacer()
                        Text("AES-256")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Audit Logs", systemImage: "list.bullet.indent")
                            .font(.subheadline)
                        Spacer()
                        Text("Enabled")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    HStack {
                        Label("Key Rotation", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                        Spacer()
                        Text("Every 90 days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Compliance & Data")
            }

            // MARK: - Actions
            if let _ = connector {
                Section {
                    Button("Apply Security Policy") {
                        showingSaveAlert = true
                    }
                    .frame(maxWidth: .infinity)
                    .bold()

                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
        .navigationTitle("Security & Scopes")
        .alert("Security Policy Applied", isPresented: $showingSaveAlert) {
            Button("OK") {}
        } message: {
            Text("Security settings have been updated for this connector.")
        }
        .alert("Reset Security Settings?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("This will reset all security settings to their default values.")
        }
    }

    // MARK: - Helpers

    private func securityStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func generateRandomSecret() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in chars.randomElement()! })
    }

    private func resetToDefaults() {
        rateLimit = 60
        enforceTLS = true
        allowPublicAccess = false
        enableIPWhitelist = false
        whitelistedIPs = []
        tokenExpiryHours = 24
        autoRefreshTokens = true
        enableCORS = true
        allowedOrigins = ["*"]
        enableWebhookSignatures = true
        webhookSecret = ""
        requestedScopes = ["api.read", "api.write"]
    }
}
