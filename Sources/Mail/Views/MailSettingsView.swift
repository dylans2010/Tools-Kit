import SwiftUI

struct MailSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var accountManager = AccountManager.shared

    @AppStorage("mail.settings.undoSendEnabled") private var undoSendEnabled = true
    @AppStorage("mail.settings.undoSendDelay") private var undoSendDelay = 10
    @AppStorage("mail.settings.defaultSenderAccountId") private var defaultSenderAccountId = ""

    @AppStorage("mail.settings.unifiedInbox") private var unifiedInboxEnabled = true
    @AppStorage("mail.settings.threadedConversations") private var threadedConversationsEnabled = true
    @AppStorage("mail.settings.sortOrder") private var sortOrder = "newest"
    @AppStorage("mail.settings.showAvatars") private var showAvatars = true
    @AppStorage("mail.settings.previewLines") private var previewLines = 2

    @AppStorage("mail.settings.ai.autoSummarize") private var autoSummarizeEmails = true
    @AppStorage("mail.settings.ai.smartReply") private var smartReplySuggestions = true
    @AppStorage("mail.settings.ai.autoCategorize") private var autoCategorizeEmails = true

    @State private var signatures: [String: String] = [:]
    @State private var showManageAccounts = false
    @State private var showAutomationRules = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                Form {
                    Section {
                        accountManagementButton
                    }
                    .listRowBackground(Color.workspaceSurface)

                    Section("Automation & AI") {
                        Button { showAutomationRules = true } label: {
                            Label("Workflow Automation Rules", systemImage: "bolt.badge.a")
                        }

                        Toggle("Autonomous Summarization", isOn: $autoSummarizeEmails)
                        Toggle("Smart Reply Generation", isOn: $smartReplySuggestions)
                        Toggle("Intent Classification", isOn: $autoCategorizeEmails)
                    }
                    .listRowBackground(Color.workspaceSurface)

                    Section("Inbox Appearance") {
                        Toggle("Unified Inbox", isOn: $unifiedInboxEnabled)
                        Toggle("Threaded Conversations", isOn: $threadedConversationsEnabled)

                        Picker("Preview Depth", selection: $previewLines) {
                            Text("1 Line").tag(1)
                            Text("2 Lines").tag(2)
                            Text("3 Lines").tag(3)
                        }
                    }
                    .listRowBackground(Color.workspaceSurface)

                    Section("Signatures") {
                        ForEach(accountManager.accounts) { account in
                            VStack(alignment: .leading) {
                                Text(account.emailAddress).font(.caption.bold()).foregroundStyle(.secondary)
                                TextField("Signature", text: Binding(
                                    get: { signatures[account.id] ?? "" },
                                    set: { signatures[account.id] = $0; saveSignatures() }
                                ))
                            }
                        }
                    }
                    .listRowBackground(Color.workspaceSurface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Mail Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showManageAccounts) {
                ManageAccountsView()
            }
            .sheet(isPresented: $showAutomationRules) {
                AutomationRulesView()
            }
            .onAppear {
                loadSignatures()
            }
        }
    }

    private var accountManagementButton: some View {
        Button {
            showManageAccounts = true
        } label: {
            HStack {
                Label("Manage Connected Accounts", systemImage: "person.crop.circle.badge.gearshape.fill")
                Spacer()
                Text("\(accountManager.accounts.count)").foregroundStyle(.secondary)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.white)
    }

    private func loadSignatures() {
        signatures = MailSettingsPersistence.loadDictionary(forKey: "mail.settings.signatures")
    }

    private func saveSignatures() {
        MailSettingsPersistence.saveDictionary(signatures, forKey: "mail.settings.signatures")
    }
}

struct AutomationRulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Active Pipelines") {
                    Text("If sender contains 'CEO' then Priority = 1.0")
                    Text("If intent is 'meeting_request' then Create Calendar Event")
                }

                Section {
                    Button("Create New Rule") {
                        // Logic to add rule
                    }
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Automation Rules")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
