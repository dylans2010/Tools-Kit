import SwiftUI

struct CSVParserTool: DevTool {
    let id = UUID()
    let name = "CSV Parser"
    let category: DevToolCategory = .data
    let icon = "tablecells"
    let description = "Parse and display CSV data in a table"
    func render() -> some View { CSVParserDevToolView() }
}

struct CSVParserDevToolView: View {
    @State private var input = "Name,Age,City\nAlice,30,NYC\nBob,25,LA\nCharlie,35,Chicago"
    @State private var headers: [String] = []
    @State private var rows: [[String]] = []
    @State private var delimiter = ","
    var body: some View {
        Form {
            Section("CSV Input") {
                TextEditor(text: $input).frame(minHeight: 100).font(.system(.caption, design: .monospaced))
            }
            Section {
                Picker("Delimiter", selection: $delimiter) {
                    Text("Comma").tag(",")
                    Text("Tab").tag("\t")
                    Text("Semicolon").tag(";")
                    Text("Pipe").tag("|")
                }
                Button("Parse") { parse() }
                    .disabled(input.isEmpty)
            }
            if !headers.isEmpty {
                Section("Table (\(rows.count) rows)") {
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 16) {
                                ForEach(headers, id: \.self) { h in
                                    Text(h).font(.caption.bold()).frame(minWidth: 60)
                                }
                            }
                            Divider()
                            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                                HStack(spacing: 16) {
                                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                        Text(cell).font(.system(.caption, design: .monospaced)).frame(minWidth: 60)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("CSV Parser")
    }
    private func parse() {
        let lines = input.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let first = lines.first else { return }
        headers = first.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: .whitespaces) }
        rows = lines.dropFirst().map { $0.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: .whitespaces) } }
    }
}
