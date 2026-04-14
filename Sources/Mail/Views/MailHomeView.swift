import SwiftUI

struct MailHomeView: View {
    @State private var accounts: [MailAccount] = []
    @State private var showingSetup = false

    var body: some View {
        Group {
            if accounts.isEmpty {
                emptyState
            } else {
                accountsList
            }
        }
        .navigationTitle("Mail")
        .toolbar {
            if !accounts.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSetup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSetup, onDismiss: loadAccounts) {
            NavigationStack {
                MailProviderView()
            }
        }
        .onAppear(perform: loadAccounts)
    }

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.indigo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 52))
                    .foregroundColor(.white)
            }
            .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)

            VStack(spacing: 12) {
                Text("Workspace Mail")
                    .font(.title.bold())
                Text("Connect your iCloud Mail using an app-specific password to get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                showingSetup = true
            } label: {
                Label("Connect iCloud Mail", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .padding(.horizontal, 32)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var accountsList: some View {
        List {
            ForEach(accounts) { account in
                Section {
                    FolderLink(folder: .inbox, icon: "tray.fill", account: account)
                    FolderLink(folder: .starred, icon: "star.fill", account: account)
                    FolderLink(folder: .sent, icon: "paperplane.fill", account: account)
                    FolderLink(folder: .drafts, icon: "doc.fill", account: account)
                    FolderLink(folder: .trash, icon: "trash.fill", account: account)

                    NavigationLink {
                        InboxView(account: account, folder: .inbox, filter: .unread)
                    } label: {
                        Label("Catch Up (Unread)", systemImage: "sparkles")
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                    }

                    NavigationLink {
                        MailAccountsView()
                    } label: {
                        Label("Manage Account", systemImage: "gearshape")
                    }
                } header: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 36, height: 36)
                            Text(String(account.email.prefix(1)).uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(account.email)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text(account.provider.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
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

