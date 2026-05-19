import SwiftUI

struct KeychainViewerDevTool: DevTool {
    let id = "keychain-viewer"
    let name = "Keychain Viewer"
    let category = DevToolCategory.security
    let icon = "key.viewfinder"
    let description = "Inspect and manage app keychain entries"

    func render() -> some View {
        KeychainViewerView()
    }
}

struct KeychainViewerView: View {
    @StateObject private var viewModel = KeychainViewerViewModel()
    @State private var showingAddSheet = false

    var body: some View {
        List {
            Section("App Keychain Index") {
                if viewModel.items.isEmpty {
                    ContentUnavailableView("Empty Vault", systemImage: "key.viewfinder", description: Text("No generic password entries found for this application bundle."))
                } else {
                    ForEach(viewModel.items) { item in
                        KeychainEntryRow(item: item)
                    }
                    .onDelete(perform: viewModel.delete)
                }
            }

            Section {
                Button { showingAddSheet = true } label: {
                    Label("Manually Add Entry", systemImage: "plus.key.fill")
                }

                Button("Export Secure Backup") { /* Implementation */ }
            }
        }
        .navigationTitle("Keychain")
        .refreshable { viewModel.load() }
        .onAppear { viewModel.load() }
        .sheet(isPresented: $showingAddSheet) {
            AddKeychainEntryView(viewModel: viewModel)
        }
    }
}

struct KeychainEntryRow: View {
    let item: KeychainItem
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.account).font(.subheadline.bold())
                Text(item.service).font(.system(size: 9)).foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button("Copy Password") { /* SecItemCopyMatching */ }
                Button("Copy Metadata") { UIPasteboard.general.string = "\(item.service):\(item.account)" }
            } label: {
                Image(systemName: "ellipsis.circle").foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct AddKeychainEntryView: View {
    @ObservedObject var viewModel: KeychainViewerViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Service (e.g. com.app.api)", text: $viewModel.newService)
                    TextField("Account (e.g. username)", text: $viewModel.newAccount)
                }
                Section("Secret") {
                    SecureField("Password / Token", text: $viewModel.newValue)
                }
            }
            .navigationTitle("New Secure Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(viewModel.newService.isEmpty || viewModel.newAccount.isEmpty || viewModel.newValue.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct KeychainItem: Identifiable {
    let id = UUID()
    let service: String
    let account: String
}

class KeychainViewerViewModel: ObservableObject {
    @Published var items: [KeychainItem] = []
    @Published var newService = "com.toolskit.sdk"
    @Published var newAccount = "api_token"
    @Published var newValue = ""

    func load() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let results = result as? [[String: Any]] {
            items = results.compactMap { dict in
                let service = dict[kSecAttrService as String] as? String ?? "Unknown"
                let account = dict[kSecAttrAccount as String] as? String ?? "Unknown"
                return KeychainItem(service: service, account: account)
            }
        } else {
            items = []
        }
    }

    func save() {
        load()
        newValue = ""
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}

#Preview {
    KeychainViewerView()
}
