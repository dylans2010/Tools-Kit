import SwiftUI

struct AuthServiceManagerView: View {
    @State private var showingAddProvider = false

    @State private var providers: [AuthProviderConfig] = [
        AuthProviderConfig(id: UUID(), name: "Google OAuth", type: .oauth2, lastValidated: Date(), status: .healthy),
        AuthProviderConfig(id: UUID(), name: "Main API Key", type: .apiKey, lastValidated: Date().addingTimeInterval(-86400), status: .warning),
        AuthProviderConfig(id: UUID(), name: "Customer SSO", type: .saml, lastValidated: Date(), status: .healthy)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                tokenHealthPanel

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Connected Auth Providers").font(.headline)
                        Spacer()
                        Button {
                            showingAddProvider = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }

                    ForEach(providers) { provider in
                        providerCard(provider)
                    }
                }

                perAppAssignmentMatrix
                credentialVaultSummary
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Auth Services")
        .sheet(isPresented: $showingAddProvider) {
            Text("Add Provider UI")
        }
    }

    private var tokenHealthPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Token Health").font(.headline)

            HStack(spacing: 12) {
                healthMetric(label: "Valid", value: "8", color: .green)
                healthMetric(label: "Expiring", value: "2", color: .orange)
                healthMetric(label: "Revoked", value: "0", color: .secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func healthMetric(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func providerCard(_ config: AuthProviderConfig) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name).font(.subheadline.bold())
                    Text(config.type.rawValue).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(config.status)
            }

            Divider()

            HStack {
                Text("Last Validated: \(config.lastValidated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Rotate") {}.font(.caption.bold())
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private func statusBadge(_ status: AuthProviderConfig.ConfigStatus) -> some View {
        let color: Color = status == .healthy ? .green : (status == .warning ? .orange : .red)
        return Text(status.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1), in: Capsule())
            .foregroundStyle(color)
    }

    private var perAppAssignmentMatrix: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Assignment Matrix").font(.headline)

            VStack(spacing: 0) {
                assignmentRow(app: "GitHub Pro", provider: "Google OAuth")
                Divider()
                assignmentRow(app: "Mail AI Bot", provider: "Main API Key")
                Divider()
                assignmentRow(app: "Messenger", provider: "Customer SSO")
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func assignmentRow(app: String, provider: String) -> some View {
        HStack {
            Text(app).font(.subheadline)
            Spacer()
            HStack {
                Text(provider).font(.caption).foregroundStyle(.secondary)
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding()
    }

    private var credentialVaultSummary: some View {
        HStack {
            Image(systemName: "lock.shield.fill").foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text("Credential Vault").font(.subheadline.bold())
                Text("Securely storing 12 encrypted secrets.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Manage") {}.font(.caption.bold())
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
