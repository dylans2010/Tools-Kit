import SwiftUI

struct AppSandboxExplorerDevTool: DevTool {
    let id = "app-sandbox-explorer"
    let name = "App Sandbox Explorer"
    let category: DevToolCategory = .storage
    let icon = "folder.badge.gearshape"
    let description = "Browse App Sandbox directories (Documents, Library, etc.)"

    func render() -> some View {
        List {
            folderRow("Documents", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path)
            folderRow("Library", FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].path)
            folderRow("Caches", FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].path)
            folderRow("Application Support", FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].path)
            folderRow("Temporary", NSTemporaryDirectory())
        }
    }

    private func folderRow(_ name: String, _ path: String) -> some View {
        VStack(alignment: .leading) {
            Text(name).font(.headline)
            Text(path).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
