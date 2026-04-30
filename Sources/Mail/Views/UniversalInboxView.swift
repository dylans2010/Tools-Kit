import SwiftUI

struct UniversalInboxView: View {
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var sync = MailSyncService.shared
    @AppStorage("mail.universal.grouping") private var groupingMode: String = "account"
    @State private var showMailSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                List {
                    headerSection

                    if groupingMode == "unified" {
                        unifiedFeedSection
                    } else {
                        accountSections
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showMailSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showMailSettings) {
                MailSettingsView()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("View Mode", selection: $groupingMode) {
                Text("By Account").tag("account")
                Text("Unified").tag("unified")
            }
            .pickerStyle(.segmented)

            HStack {
                Text("\(accountManager.accounts.count) Connected Accounts")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button { Task { await sync.fetchThreads(account: accountManager.accounts.first!, folder: .inbox) } } label: {
                    Label("Sync All", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.bold())
                }
            }
        }
        .padding()
        .listRowBackground(Color.clear)
    }

    private var accountSections: some View {
        ForEach(accountManager.accounts) { account in
            NavigationLink(destination: InboxView(account: account, folder: .inbox)) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "envelope.fill").foregroundStyle(.blue))

                    VStack(alignment: .leading) {
                        Text(account.emailAddress).font(.subheadline.bold())
                        Text(account.providerType.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.workspaceSurface)
        }
    }

    private var unifiedFeedSection: some View {
        Section("All Messages") {
            Text("Unified inbox content powered by AI triage.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .listRowBackground(Color.workspaceSurface)
    }
}
