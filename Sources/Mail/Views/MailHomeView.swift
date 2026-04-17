import SwiftUI

struct MailHomeView: View {
    @StateObject private var viewModel = MailViewModel()
    @State private var email = ""
    @State private var appPassword = ""

    /// Account created after a successful iCloud login — triggers navigation to InboxView.
    @State private var authenticatedAccount: MailAccount?

    var body: some View {
        NavigationStack {
            Group {
                if let account = authenticatedAccount {
                    InboxView(account: account, folder: .inbox)
                } else {
                    SignInView(
                        viewModel: viewModel,
                        email: $email,
                        appPassword: $appPassword
                    )
                }
            }
            .navigationTitle(authenticatedAccount == nil ? "iCloud Mail" : "Mail")
            .background(
                LinearGradient(
                    colors: [Color(red: 0.96, green: 0.98, blue: 1.0), Color(red: 0.92, green: 0.95, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
        .onChange(of: viewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated, !email.isEmpty {
                let account = MailAccount(
                    id: UUID(),
                    email: email,
                    provider: .iCloud,
                    isEnabled: true
                )
                // Persist the account so MailStorageService / MailSyncService can use it
                var accounts = MailStorageService.shared.loadAccounts()
                if !accounts.contains(where: { $0.email == account.email }) {
                    accounts.append(account)
                    MailStorageService.shared.saveAccounts(accounts)
                }
                authenticatedAccount = account
            } else if !isAuthenticated {
                authenticatedAccount = nil
            }
        }
        .onAppear {
            // Restore a previously saved account if the user is already authenticated
            if let saved = MailStorageService.shared.loadAccounts().first {
                authenticatedAccount = saved
            }
        }
    }
}

// MARK: - Sign-In Form

struct SignInView: View {
    @ObservedObject var viewModel: MailViewModel
    @Binding var email: String
    @Binding var appPassword: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connect iCloud")
                        .font(.largeTitle.bold())
                    Text("Sign in with your Apple ID email and an app-specific password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)
                        TextField("iCloud Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled(true)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 10) {
                        Image(systemName: "key")
                            .foregroundColor(.secondary)
                        SecureField("App-Specific Password", text: $appPassword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    Link("Generate app-specific password at appleid.apple.com",
                         destination: URL(string: "https://appleid.apple.com")!)
                    .font(.footnote)
                }

                Button(action: signIn) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "icloud")
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .disabled(email.isEmpty || appPassword.isEmpty || viewModel.isLoading)

                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(10)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tip")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Text("Use an @icloud.com, @me.com, or @mac.com address with an Apple app-specific password.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
    }

    private func signIn() {
        guard email.hasSuffix("@icloud.com")
                || email.hasSuffix("@me.com")
                || email.hasSuffix("@mac.com") else {
            viewModel.errorMessage = "Please enter a valid @icloud.com, @me.com, or @mac.com email address."
            return
        }
        viewModel.signIn(email: email, appPassword: appPassword)
    }
}
