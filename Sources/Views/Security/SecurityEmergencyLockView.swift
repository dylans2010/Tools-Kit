import SwiftUI

struct SecurityEmergencyLockView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingConfirmation = false

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "exclamationmark.lock.fill")
                .font(.system(size: 100))
                .foregroundStyle(.red)
                .padding(.top, 40)

            VStack(spacing: 12) {
                Text("Emergency Lock")
                    .font(.largeTitle.bold())
                Text("Activating Emergency Lock will immediately revoke all active sessions, lock the vault, and require a full master password re-authentication.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showingConfirmation = true
            } label: {
                Text("ACTIVATE EMERGENCY LOCK")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .confirmationDialog("Activate Emergency Lock?", isPresented: $showingConfirmation, titleVisibility: .visible) {
                Button("LOCK EVERYTHING", role: .destructive) {
                    // Emergency lock logic
                    AuthService.shared.logout()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }

            Button("Cancel") {
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 20)
        }
        .background(Color(uiColor: .systemBackground))
    }
}
