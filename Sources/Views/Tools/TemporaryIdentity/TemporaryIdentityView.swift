import SwiftUI

struct TemporaryIdentityTool: Tool {
    let name = "Identity Generator"
    let icon = "person.crop.circle.badge.questionmark"
    let category = ToolCategory.privacy
    let complexity = ToolComplexity.basic
    let description = "Generate realistic fake identities for testing and privacy"
    let requiresAPI = false
    var view: AnyView { AnyView(TemporaryIdentityView()) }
}

struct TemporaryIdentityView: View {
    @StateObject private var backend = TemporaryIdentityBackend()

    var body: some View {
        ToolDetailView(tool: TemporaryIdentityTool()) {
            VStack(spacing: 16) {
                generateButton
                if let identity = backend.currentIdentity {
                    identityCard(identity)
                }
                if !backend.history.isEmpty {
                    historySection
                }
            }
        }
        .navigationTitle("Identity Generator")
    }

    private var generateButton: some View {
        Button {
            backend.generate()
        } label: {
            Label("Generate Identity", systemImage: "person.fill.badge.plus")
                .frame(maxWidth: .infinity).padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
    }

    private func identityCard(_ identity: TemporaryIdentity) -> some View {
        ToolInputSection("Generated Identity") {
            VStack(spacing: 0) {
                identityRow(icon: "person.fill", label: "Name", value: identity.fullName)
                Divider().padding(.leading, 44)
                identityRow(icon: "envelope.fill", label: "Email", value: identity.email)
                Divider().padding(.leading, 44)
                identityRow(icon: "phone.fill", label: "Phone", value: identity.phone)
                Divider().padding(.leading, 44)
                identityRow(icon: "house.fill", label: "Address", value: "\(identity.address), \(identity.city)")
                Divider().padding(.leading, 44)
                identityRow(icon: "globe", label: "Country", value: identity.country)
                Divider().padding(.leading, 44)
                identityRow(icon: "calendar", label: "Date of Birth", value: identity.dateOfBirth)
                Divider().padding(.leading, 44)
                identityRow(icon: "at", label: "Username", value: identity.username)
                Divider().padding(.leading, 44)
                identityRow(icon: "key.fill", label: "Password", value: identity.password, monospaced: true)

                Divider()
                Button {
                    copyAll(identity)
                } label: {
                    Label("Copy All to Clipboard", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
    }

    private func identityRow(icon: String, label: String, value: String, monospaced: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 20)
            Text(label).foregroundColor(.secondary).font(.subheadline)
            Spacer()
            Text(value)
                .font(monospaced ? .system(.caption, design: .monospaced) : .subheadline)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal).padding(.vertical, 10)
    }

    private var historySection: some View {
        ToolInputSection("History (\(backend.history.count))") {
            VStack(spacing: 0) {
                ForEach(backend.history) { identity in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(identity.fullName).font(.subheadline.weight(.medium))
                            Text(identity.email).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(identity.generatedAt, style: .relative)
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    .padding()
                    if identity.id != backend.history.last?.id { Divider().padding(.leading) }
                }
                Divider()
                Button(role: .destructive) {
                    backend.clearHistory()
                } label: {
                    Label("Clear History", systemImage: "trash")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding()
            }
        }
    }

    private func copyAll(_ identity: TemporaryIdentity) {
        let text = """
        Name: \(identity.fullName)
        Email: \(identity.email)
        Phone: \(identity.phone)
        Address: \(identity.address), \(identity.city), \(identity.country) \(identity.zipCode)
        DOB: \(identity.dateOfBirth)
        Username: \(identity.username)
        Password: \(identity.password)
        """
        UIPasteboard.general.string = text
    }
}
