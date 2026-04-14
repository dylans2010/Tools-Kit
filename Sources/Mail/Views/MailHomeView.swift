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
                    Section(header: Text("Intelligence")) {
                        NavigationLink(destination: InboxView(account: accounts.first!, folder: .inbox, filter: .unread)) {
                            Label {
                                Text("Unified Catch Up")
                                    .fontWeight(.semibold)
                            } icon: {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(
                                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                            }
                        }
                    }

                    ForEach(accounts) { account in
                        Section(header: Text(account.email)) {
                            FolderLink(folder: .inbox, icon: "tray.fill", account: account)
                            FolderLink(folder: .starred, icon: "star.fill", account: account)
                            FolderLink(folder: .sent, icon: "paperplane.fill", account: account)
                            FolderLink(folder: .drafts, icon: "doc.fill", account: account)
                            FolderLink(folder: .trash, icon: "trash.fill", account: account)
                        }
                    }

                    Section {
                        NavigationLink(destination: MailAccountsView()) {
                            Label("Manage Accounts", systemImage: "gearshape")
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
        if !accounts.isEmpty {
            Task {
                await MailSyncService.shared.syncAll()
            }
        }
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
