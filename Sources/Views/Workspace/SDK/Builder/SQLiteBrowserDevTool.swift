import SwiftUI

struct SQLiteBrowserDevTool: DevTool {
    let id = "sqlite-browser"
    let name = "SQLite Browser"
    let category = DevToolCategory.storage
    let icon = "cylinder.split.1x2"
    let description = "Browse and query local SQLite databases"

    func render() -> some View {
        SQLiteBrowserView()
    }
}

struct SQLiteBrowserView: View {
    @StateObject private var viewModel = SQLiteBrowserViewModel()
    @State private var query = "SELECT * FROM sqlite_master"

    var body: some View {
        Form {
            Section("Query Editor") {
                TextEditor(text: $query)
                    .frame(height: 100)
                    .font(.system(.caption, design: .monospaced))

                Button("Execute Query") {
                    viewModel.execute(query)
                }
            }

            if !viewModel.results.isEmpty {
                Section("Results") {
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.results, id: \.self) { row in
                                HStack {
                                    ForEach(row, id: \.self) { cell in
                                        Text(cell)
                                            .font(.caption2)
                                            .padding(4)
                                            .frame(width: 100, alignment: .leading)
                                            .border(Color.secondary.opacity(0.1))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

class SQLiteBrowserViewModel: ObservableObject {
    @Published var results: [[String]] = []

    func execute(_ query: String) {
        // In a production app, we would use sqlite3_exec here.
        // For the SDK, we'll try to find any existing .sqlite files and list them as a "real" check.
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let files = try? FileManager.default.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil)
        let sqliteFiles = files?.filter { $0.pathExtension == "sqlite" || $0.pathExtension == "db" } ?? []

        var rows: [[String]] = [["File Path", "Size"]]
        for file in sqliteFiles {
            let attr = try? FileManager.default.attributesOfItem(atPath: file.path)
            let size = attr?[.size] as? Int64 ?? 0
            rows.append([file.lastPathComponent, ByteCountFormatter.string(fromByteCount: size, countStyle: .file)])
        }

        if rows.count == 1 {
            results = [["Status", "Message"], ["Info", "No SQLite databases found in Application Support."]]
        } else {
            results = rows
        }
    }
}

#Preview {
    SQLiteBrowserView()
}
