import SwiftUI

struct KeychainViewerDevTool: DevTool {
    let id = "keychain-viewer"
    let name = "Keychain Viewer"
    let category = DevToolCategory.security
    let icon = "key.fill"
    let description = "View app-specific keychain items"

    func render() -> some View {
        KeychainViewerView()
    }
}

struct KeychainViewerView: View {
    var body: some View {
        List {
            Section("App Keychain") {
                Text("Searching Security Services for generic password items...")
                    .foregroundStyle(.secondary)
            }

            Section("Status") {
                LabeledContent("Keychain Access", value: "Available")
            }
        }
    }
}
