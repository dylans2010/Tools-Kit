import SwiftUI

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @State private var keyValue: String?
    @State private var metadata: KeyMetadata?
    @State private var errorMessage: String?
    @State private var currentTier: KeyTier = DeveloperIDManager.currentBuildTier()
    @State private var showSessionStatus = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header

                if let errorMessage {
                    errorBanner(errorMessage)
                }

                statusCard

                if let keyValue {
                    keyDisplayCard(keyValue)
                }

                metadataCard

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#0A0F1E"), Color(hex: "#121C36")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Session Status") {
                        showSessionStatus = true
                    }
                }
            }
            .navigationDestination(isPresented: $showSessionStatus) {
                SessionStatusView(state: sessionStatusState) {
                    showSessionStatus = false
                    loadStoredKey()
                }
            }
            .onAppear {
                loadStoredKey()
                if authorizationManager.authState == .authenticated {
                    dismiss()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Developer Identity")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text("Secure access key for workspace SDK sessions")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if metadata != nil {
                HStack {
                    Label("Developer ID Active", systemImage: "checkmark.seal.fill")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.green)
                    Spacer()
                }

                Button(role: .destructive) {
                    revokeKey()
                } label: {
                    Text("Revoke")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    generateKey()
                } label: {
                    Text("Generate Developer ID")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#3D8EFF"))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func keyDisplayCard(_ key: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Developer ID")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)

            Text(key)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    UIPasteboard.general.string = key
                }

            Text("Tap key to copy")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var metadataCard: some View {
        if let metadata {
            VStack(alignment: .leading, spacing: 10) {
                Text("Metadata")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)

                HStack {
                    Text("Tier")
                    Spacer()
                    Text(metadata.tier.rawValue)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#3D8EFF").opacity(0.3), in: Capsule())
                }
                .foregroundStyle(.white)

                HStack {
                    Text("Generated")
                    Spacer()
                    Text(metadata.generatedAt.formatted(date: .abbreviated, time: .shortened))
                }
                .foregroundStyle(.white.opacity(0.85))

                HStack {
                    Text("Expires")
                    Spacer()
                    Text(metadata.expiryDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Never")
                }
                .foregroundStyle(.white.opacity(0.85))
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
    }

    private func loadStoredKey() {
        isLoading = true
        errorMessage = nil
        do {
            guard let stored = try DeveloperIDManager.shared.retrieveStoredKey() else {
                metadata = nil
                keyValue = nil
                isLoading = false
                return
            }

            let validated = try DeveloperIDManager.shared.validate(stored)
            keyValue = stored
            metadata = validated
            currentTier = validated.tier
            isLoading = false
        } catch let validationError as KeyValidationError {
            if case .expired = validationError {
                try? DeveloperIDManager.shared.deleteStoredKey()
                keyValue = nil
                metadata = nil
            }
            errorMessage = validationError.localizedDescription
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            keyValue = nil
            metadata = nil
            isLoading = false
        }
    }

    private func generateKey() {
        errorMessage = nil
        do {
            let key = try DeveloperIDManager.shared.generateKey(tier: currentTier)
            let validated = try DeveloperIDManager.shared.validate(key)
            keyValue = key
            metadata = validated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func revokeKey() {
        errorMessage = nil
        do {
            try DeveloperIDManager.shared.deleteStoredKey()
            keyValue = nil
            metadata = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var sessionStatusState: SessionStatusView.State {
        if isLoading { return .loading }
        if metadata != nil { return .active }
        if let errorMessage, errorMessage.localizedCaseInsensitiveContains("expired") { return .expired }
        if let errorMessage { return .error(message: errorMessage) }
        return .expired
    }
}
