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
    @State private var query = "SELECT name FROM sqlite_master WHERE type='table'"
    @State private var showingTableInspector = false

    var body: some View {
        List {
            Section("Database Files") {
                if viewModel.dbFiles.isEmpty {
                    Text("No databases found in app sandbox.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.dbFiles, id: \.path) { file in
                        HStack {
                            Image(systemName: "cylinder.split.1x2.fill")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(file.lastPathComponent).font(.subheadline.bold())
                                Text(viewModel.fileSize(file)).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.selectedFile == file {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.selectedFile = file }
                    }
                }
            }

            Section("SQL Console") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $query)
                        .frame(height: 100)
                        .font(.system(.caption, design: .monospaced))
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .padding(8)
                }

                HStack {
                    Button {
                        viewModel.execute(query)
                    } label: {
                        Label("Execute", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.selectedFile == nil || query.isEmpty)

                    Spacer()

                    Menu("Templates") {
                        Button("List Tables") { query = "SELECT name FROM sqlite_master WHERE type='table'" }
                        Button("Table Schema") { query = "PRAGMA table_info('table_name')" }
                        Button("Count Rows") { query = "SELECT COUNT(*) FROM table_name" }
                    }
                }
            }

            if !viewModel.results.isEmpty {
                Section("Results (\(viewModel.results.count - 1) rows)") {
                    ScrollView(.horizontal, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 0) {
                            // Header
                            if let header = viewModel.results.first {
                                ResultRowView(cells: header, isHeader: true)
                            }

                            // Body
                            ForEach(Array(viewModel.results.dropFirst().enumerated()), id: \.offset) { _, row in
                                ResultRowView(cells: row, isHeader: false)
                            }
                        }
                    }
                    .frame(maxHeight: 400)

                    Button("Export Results to CSV") {
                        viewModel.exportResults()
                    }
                    .font(.caption)
                }
            }
        }
        .navigationTitle("SQLite Browser")
        .onAppear { viewModel.scanForDatabases() }
    }
}

struct ResultRowView: View {
    let cells: [String]
    let isHeader: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                Text(cell)
                    .font(.system(size: 10, design: .monospaced))
                    .bold(isHeader)
                    .padding(8)
                    .frame(width: 120, alignment: .leading)
                    .background(isHeader ? Color(.systemGray4) : Color.clear)
                    .border(Color.secondary.opacity(0.2), width: 0.5)
            }
        }
    }
}

class SQLiteBrowserViewModel: ObservableObject {
    @Published var results: [[String]] = []
    @Published var dbFiles: [URL] = []
    @Published var selectedFile: URL?

    func scanForDatabases() {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

        var files: [URL] = []
        let searchURLs = [documents, appSupport]

        for url in searchURLs {
            if let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
                let dbs = contents.filter { $0.pathExtension == "sqlite" || $0.pathExtension == "db" || $0.lastPathComponent.contains("Store") }
                files.append(contentsOf: dbs)
            }
        }

        self.dbFiles = files
        if selectedFile == nil { selectedFile = files.first }
    }

    func execute(_ query: String) {
        // Mock execution for SDK UI demonstration
        if query.lowercased().contains("select name from sqlite_master") {
            results = [
                ["name", "type", "tbl_name"],
                ["Users", "table", "Users"],
                ["Settings", "table", "Settings"],
                ["LogCache", "table", "LogCache"]
            ]
        } else {
            results = [
                ["ID", "Value", "Timestamp"],
                ["1", "Sample Entry A", "2024-05-20"],
                ["2", "Sample Entry B", "2024-05-21"],
                ["3", "Sample Entry C", "2024-05-22"]
            ]
        }
    }

    func fileSize(_ url: URL) -> String {
        let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = attr?[.size] as? Int64 ?? 0
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    func exportResults() {
        let csv = results.map { $0.joined(separator: ",") }.joined(separator: "\n")
        UIPasteboard.general.string = csv
    }
}

#Preview {
    SQLiteBrowserView()
}
