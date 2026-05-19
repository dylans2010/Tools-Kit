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

    var body: some View {
        List {
            Section("Keychain Items") {
                if viewModel.items.isEmpty {
                    Text("No items found").foregroundStyle(.secondary)
                } else {
                    ForEach($viewModel.items) { $item in
                        VStack(alignment: .leading) {
                            Text(item.account).font(.headline)
                            Text(item.service).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: viewModel.delete)
                }
            }

            Section("Add Entry") {
                TextField("Service", text: $viewModel.newService)
                TextField("Account", text: $viewModel.newAccount)
                SecureField("Value", text: $viewModel.newValue)
                Button("Save Entry") { viewModel.save() }
                    .disabled(viewModel.newService.isEmpty || viewModel.newAccount.isEmpty)
            }
        }
        .refreshable { viewModel.load() }
        .onAppear { viewModel.load() }
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
