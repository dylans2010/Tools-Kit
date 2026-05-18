import SwiftUI

struct SQLiteBrowserTool: DevTool {
    let id = UUID()
    let name = "SQLite Browser"
    let category: DevToolCategory = .storage
    let icon = "cylinder.split.1x2"
    let description = "Browse SQLite databases in the app sandbox"
    func render() -> some View { SQLiteBrowserDevToolView() }
}

struct SQLiteBrowserDevToolView: View {
    @State private var databases: [URL] = []
    @State private var selectedDB: URL?
    @State private var tables: [String] = []
    @State private var queryResult: [[String]] = []
    @State private var columns: [String] = []
    @State private var query = "SELECT name FROM sqlite_master WHERE type='table'"
    @State private var errorMsg: String?
    @State private var isScanning = false

    var body: some View {
        Form {
            Section {
                Button(action: scanForDatabases) {
                    HStack {
                        Label("Scan for Databases", systemImage: "magnifyingglass")
                        if isScanning { Spacer(); ProgressView().controlSize(.small) }
                    }
                }
            }
            if !databases.isEmpty {
                Section("Found Databases (\(databases.count))") {
                    ForEach(databases, id: \.path) { db in
                        Button {
                            selectedDB = db
                        } label: {
                            VStack(alignment: .leading) {
                                Text(db.lastPathComponent).font(.subheadline)
                                Text(db.deletingLastPathComponent().path)
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            if selectedDB != nil {
                Section("Query") {
                    TextEditor(text: $query)
                        .frame(minHeight: 60)
                        .font(.system(.caption, design: .monospaced))
                    Button("Execute") { executeQuery() }
                }
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if !columns.isEmpty {
                Section("Results (\(queryResult.count) rows)") {
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 12) {
                                ForEach(columns, id: \.self) { col in
                                    Text(col).font(.caption.bold()).frame(minWidth: 80)
                                }
                            }
                            Divider()
                            ForEach(Array(queryResult.prefix(100).enumerated()), id: \.offset) { _, row in
                                HStack(spacing: 12) {
                                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                        Text(cell).font(.system(.caption2, design: .monospaced)).frame(minWidth: 80)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("SQLite Browser")
    }

    private func scanForDatabases() {
        isScanning = true
        databases.removeAll()
        let dirs = [
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first,
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
        ].compactMap { $0 }
        for dir in dirs {
            if let en = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil) {
                for case let url as URL in en {
                    let ext = url.pathExtension.lowercased()
                    if ext == "sqlite" || ext == "db" || ext == "sqlite3" {
                        databases.append(url)
                    }
                }
            }
        }
        isScanning = false
    }

    private func executeQuery() {
        errorMsg = nil; columns.removeAll(); queryResult.removeAll()
        guard let db = selectedDB else { errorMsg = "No database selected"; return }
        errorMsg = "Direct SQLite queries require the sqlite3 C API. Use the File Explorer to locate database files."
    }
}
