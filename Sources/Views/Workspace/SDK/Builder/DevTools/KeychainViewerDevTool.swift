import SwiftUI
import Security

struct KeychainViewerTool: DevTool {
    let id = UUID()
    let name = "Keychain Viewer"
    let category: DevToolCategory = .security
    let icon = "key"
    let description = "Browse Keychain items"
    func render() -> some View { KeychainViewerDevToolView() }
}

struct KeychainViewerDevToolView: View {
    @State private var items: [KeychainItem] = []
    @State private var errorMsg: String?

    struct KeychainItem: Identifiable {
        let id = UUID()
        let itemClass: String
        let account: String
        let service: String
        let accessGroup: String
        let created: Date?
    }

    var body: some View {
        Form {
            Section {
                Button("Query Keychain") { queryKeychain() }
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) }
            }
            if items.isEmpty {
                Section {
                    ContentUnavailableView("No Items", systemImage: "key.slash",
                        description: Text("No accessible keychain items found."))
                }
            } else {
                Section("Items (\(items.count))") {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "key.fill").foregroundStyle(.accent)
                                Text(item.account.isEmpty ? "(no account)" : item.account)
                                    .font(.subheadline.weight(.medium))
                            }
                            if !item.service.isEmpty {
                                LabeledContent("Service", value: item.service).font(.caption)
                            }
                            LabeledContent("Class", value: item.itemClass).font(.caption)
                            if let created = item.created {
                                LabeledContent("Created") { Text(created, style: .date) }.font(.caption)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Keychain Viewer")
    }

    private func queryKeychain() {
        items.removeAll(); errorMsg = nil
        let classes: [(String, CFString)] = [
            ("Generic Password", kSecClassGenericPassword),
            ("Internet Password", kSecClassInternetPassword),
        ]
        for (name, secClass) in classes {
            let query: [String: Any] = [
                kSecClass as String: secClass,
                kSecReturnAttributes as String: true,
                kSecMatchLimit as String: kSecMatchLimitAll,
            ]
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            if status == errSecSuccess, let entries = result as? [[String: Any]] {
                for entry in entries {
                    items.append(KeychainItem(
                        itemClass: name,
                        account: entry[kSecAttrAccount as String] as? String ?? "",
                        service: entry[kSecAttrService as String] as? String ?? "",
                        accessGroup: entry[kSecAttrAccessGroup as String] as? String ?? "",
                        created: entry[kSecAttrCreationDate as String] as? Date
                    ))
                }
            }
        }
        if items.isEmpty { errorMsg = "No accessible items or restricted by entitlements" }
    }
}
