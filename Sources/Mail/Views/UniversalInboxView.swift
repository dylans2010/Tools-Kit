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
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(providerColor(account.providerType).opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: providerIcon(for: account.providerType))
                            .foregroundStyle(providerColor(account.providerType))
                            .font(.system(size: 20, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.emailAddress)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        Text(account.providerType.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.secondary.opacity(0.5))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .buttonStyle(.plain)
        }
    }

    private func providerIcon(for provider: MailAccount.ProviderType) -> String {
        switch provider {
        case .gmail: return "g.circle.fill"
        case .outlook: return "envelope.fill"
        case .yahoo: return "y.circle.fill"
        case .icloud: return "icloud.fill"
        default: return "envelope.badge.shield.half.filled"
        }
    }

    private func providerColor(_ provider: MailAccount.ProviderType) -> Color {
        switch provider {
        case .gmail: return .red
        case .outlook: return .blue
        case .yahoo: return .purple
        case .proton: return .green
        case .icloud: return .cyan
        case .imap: return .gray
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
