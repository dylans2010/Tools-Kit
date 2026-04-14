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
            .navigationTitle("Mail")
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
        Form {
            Section(header: Text("iCloud Credentials")) {
                TextField("iCloud Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                SecureField("App-Specific Password", text: $appPassword)

                Link("Generate App-Specific Password at appleid.apple.com",
                     destination: URL(string: "https://appleid.apple.com")!)
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Section {
                Button(action: signIn) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || appPassword.isEmpty || viewModel.isLoading)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
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
