import SwiftUI

struct SQLiteBrowserDevTool: DevTool {
    let id = "sqlite-browser"
    let name = "SQLite Browser"
    let category = DevToolCategory.storage
    let icon = "database"
    let description = "Browse SQLite databases"

    func render() -> some View {
        SQLiteBrowserView()
    }
}

struct SQLiteBrowserView: View {
    var body: some View {
        List {
            Section("Search Sandbox") {
                Text("Searching for .sqlite files...")
                    .foregroundStyle(.secondary)
            }

            Section("Instruction") {
                Text("Place SQLite files in Documents directory to browse them here.")
                    .font(.caption)
            }
        }
    }
}
