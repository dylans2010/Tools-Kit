import SwiftUI
import Appwrite

struct WelcomeFlowView: View {
    @State private var username: String = ""
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Welcome to Tools Kit")
                        .font(.largeTitle.bold())

                    Text("Customize your AI experience by setting up your profile.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Display Name")
                        .font(.headline)

                    TextField("Enter username", text: $username)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text("This name will be used across all AI interactions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white)
                            }
                            Text("Save Profile")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isSaving || username.isEmpty)

                    Button("Skip for Now") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func saveProfile() {
        isSaving = true
        Task {
            do {
                let user = try await AppwriteService.account.get()
                try await AuthDatabaseService.shared.upsertUserProfile(
                    userId: user.id,
                    email: user.email,
                    name: username,
                    provider: "email" // Fallback if provider unknown here
                )
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                print("Failed to save profile: \(error.localizedDescription)")
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            }
        }
    }
}
