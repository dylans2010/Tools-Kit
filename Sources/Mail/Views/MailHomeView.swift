import SwiftUI

struct MailHomeView: View {
    @StateObject private var viewModel = MailViewModel()
    @State private var email = ""
    @State private var appPassword = ""

    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                InboxListView(viewModel: viewModel)
            } else {
                SignInView(viewModel: viewModel, email: $email, appPassword: $appPassword)
            }
        }
        .navigationTitle("Mail")
    }
}

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

                Link("Generate App-Specific Password at appleid.apple.com", destination: URL(string: "https://appleid.apple.com")!)
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
        guard email.hasSuffix("@icloud.com") || email.hasSuffix("@me.com") || email.hasSuffix("@mac.com") else {
            viewModel.errorMessage = "Please enter a valid @icloud.com, @me.com, or @mac.com email address."
            return
        }
        viewModel.signIn(email: email, appPassword: appPassword)
    }
}

struct InboxListView: View {
    @ObservedObject var viewModel: MailViewModel

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.emails.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Fetching Mail...")
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            ForEach(viewModel.filteredEmails) { email in
                NavigationLink(destination: EmailDetailView(viewModel: viewModel, email: email)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(email.sender)
                                .font(.headline)
                            Spacer()
                            Text(email.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(email.subject)
                            .font(.subheadline)
                            .lineLimit(1)
                        if !email.preview.isEmpty {
                            Text(email.preview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchQuery)
        .refreshable {
            viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.signOut() }) {
                    Text("Sign Out")
                }
            }
        }
    }
}
