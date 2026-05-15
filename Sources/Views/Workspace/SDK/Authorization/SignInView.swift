import SwiftUI

struct SignInView: View {
    @State private var activeKey: String?
    @State private var metadata: KeyMetadata?
    @State private var errorMessage: String?
    @State private var currentTier: KeyTier = .dev

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                headerSection

                if let error = errorMessage {
                    errorBanner(error)
                }

                if let key = activeKey, let meta = metadata {
                    activeKeyView(key, meta: meta)
                } else {
                    generateKeyView
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Developer Identity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadStoredKey)
    }

    // MARK: - Components

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.bottom, 8)

            Text("Developer ID")
                .font(.title.bold())

            Text("Manage your authenticated workspace identity.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.caption.bold())
                .foregroundStyle(.white)
            Spacer()
            Button {
                errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.red.opacity(0.8))
        .cornerRadius(12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func activeKeyView(_ key: String, meta: KeyMetadata) -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("STATUS")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("ACTIVE")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .cornerRadius(6)
                }

                Text(key)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .onTapGesture {
                        UIPasteboard.general.string = key
                        // Feedback could be added here
                    }

                metadataRow(label: "Environment", value: meta.tier.rawValue)
                metadataRow(label: "Generated", value: meta.generatedAt.formatted(date: .abbreviated, time: .shortened))
                metadataRow(label: "Expires", value: meta.expiryDate?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)

            Button(role: .destructive, action: revokeKey) {
                Label("Revoke Developer ID", systemImage: "trash.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }

    private var generateKeyView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Environment Tier")
                    .font(.headline)

                Picker("Tier", selection: $currentTier) {
                    Text("Development").tag(KeyTier.dev)
                    Text("Staging").tag(KeyTier.stg)
                    Text("Production").tag(KeyTier.prd)
                }
                .pickerStyle(.segmented)

                Text(tierDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)

            Button(action: generateKey) {
                Text("Generate Developer ID")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
            }
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }

    private var tierDescription: String {
        switch currentTier {
        case .dev: return "DEV keys expire after 30 days. Suitable for local testing."
        case .stg: return "STG keys expire after 90 days. For integration environments."
        case .prd: return "PRD keys never expire. For production-ready tools."
        }
    }

    // MARK: - Actions

    private func loadStoredKey() {
        do {
            if let key = try AuthRootView.shared.retrieveStoredKey() {
                activeKey = key
                metadata = try AuthRootView.shared.validate(key)
            }
        } catch {
            errorMessage = error.localizedDescription
            activeKey = nil
            metadata = nil
        }
    }

    private func generateKey() {
        withAnimation {
            do {
                let key = try AuthRootView.shared.generateKey(tier: currentTier)
                activeKey = key
                metadata = try AuthRootView.shared.validate(key)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func revokeKey() {
        withAnimation {
            do {
                try AuthRootView.shared.deleteStoredKey()
                activeKey = nil
                metadata = nil
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
