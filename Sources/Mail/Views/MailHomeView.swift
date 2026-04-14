import SwiftUI

struct MailHomeView: View {
    @State private var accounts: [MailAccount] = []
    @State private var selectedFolder: MailFolder = .inbox
    @State private var showingSetup = false

    var body: some View {
        Group {
            if accounts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    Text("Secure Workspace Mail")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Connect your iCloud Mail using an app-specific password to get started.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Setup iCloud Mail") {
                        showingSetup = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section(header: Text("Accounts")) {
                        ForEach(accounts) { account in
                            NavigationLink(destination: MailAccountsView()) {
                                Label(account.email, systemImage: "person.crop.circle")
                            }
                        }
                    }

                    Section(header: Text("Folders")) {
                        FolderLink(folder: .inbox, icon: "tray.fill", account: accounts.first!)
                        FolderLink(folder: .starred, icon: "star.fill", account: accounts.first!)
                        FolderLink(folder: .sent, icon: "paperplane.fill", account: accounts.first!)
                        FolderLink(folder: .drafts, icon: "doc.fill", account: accounts.first!)
                        FolderLink(folder: .trash, icon: "trash.fill", account: accounts.first!)
                    }

                    Section(header: Text("Intelligence")) {
                        NavigationLink(destination: InboxView(account: accounts.first!, folder: .inbox, filter: .unread)) {
                            Label("Catch Up (Unread)", systemImage: "sparkles")
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Mail")
        .sheet(isPresented: $showingSetup, onDismiss: loadAccounts) {
            NavigationStack {
                MailProviderView()
            }
        }
        .onAppear(perform: loadAccounts)
    }

    private func loadAccounts() {
        accounts = MailStorageService.shared.loadAccounts()
    }
}

struct FolderLink: View {
    let folder: MailFolder
    let icon: String
    let account: MailAccount

    var body: some View {
        NavigationLink(destination: InboxView(account: account, folder: folder)) {
            Label(folder.name, systemImage: icon)
        }
    }
}
