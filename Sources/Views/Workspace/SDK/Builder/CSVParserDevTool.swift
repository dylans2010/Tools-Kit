import SwiftUI

struct CSVParserDevTool: DevTool {
    let id = "csv-parser"
    let name = "CSV Parser"
    let category = DevToolCategory.data
    let icon = "tablecells"
    let description = "Parse, filter, sort, and export CSV data"

    func render() -> some View {
        CSVParserView()
    }
}

struct CSVParserView: View {
    @StateObject private var viewModel = CSVParserViewModel()

    var body: some View {
        Form {
            Section(header: Text("Input CSV")) {
                TextEditor(text: $viewModel.input)
                    .frame(height: 100)
                    .font(.system(.caption, design: .monospaced))
                HStack {
                    Button("Paste") {
                        if let text = UIPasteboard.general.string { viewModel.input = text }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                    Button("Clear") { viewModel.input = "" }
                        .buttonStyle(.bordered).controlSize(.small)
                    Button("Sample") {
                        viewModel.input = "id,name,role,score\n1,Alice,Engineer,95\n2,Bob,Designer,88\n3,Charlie,PM,72\n4,Diana,Engineer,91\n5,Eve,Designer,85"
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            }

            Section(header: Text("Configuration")) {
                HStack {
                    Text("Delimiter")
                        .font(.caption)
                    Picker("", selection: $viewModel.delimiter) {
                        Text(",").tag(",")
                        Text(";").tag(";")
                        Text("Tab").tag("\t")
                        Text("|").tag("|")
                    }
                    .pickerStyle(.segmented)
                }
                Toggle("Has Header Row", isOn: $viewModel.hasHeader)
            }

            Section(header: Text("Statistics")) {
                HStack(spacing: 16) {
                    VStack {
                        Text("\(viewModel.rowCount)").font(.title3.bold())
                        Text("Rows").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Text("\(viewModel.columnCount)").font(.title3.bold())
                        Text("Columns").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Text("\(viewModel.cellCount)").font(.title3.bold())
                        Text("Cells").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if viewModel.hasHeader && !viewModel.headers.isEmpty {
                Section(header: Text("Filter")) {
                    Picker("Column", selection: $viewModel.filterColumn) {
                        Text("All").tag(-1)
                        ForEach(Array(viewModel.headers.enumerated()), id: \.offset) { idx, header in
                            Text(header).tag(idx)
                        }
                    }
                    TextField("Search...", text: $viewModel.filterText)
                        .font(.caption)
                        .textInputAutocapitalization(.never)
                }

                Section(header: Text("Sort")) {
                    HStack {
                        Picker("Sort by", selection: $viewModel.sortColumn) {
                            Text("None").tag(-1)
                            ForEach(Array(viewModel.headers.enumerated()), id: \.offset) { idx, header in
                                Text(header).tag(idx)
                            }
                        }
                        Toggle(viewModel.sortAscending ? "Asc" : "Desc", isOn: $viewModel.sortAscending)
                            .toggleStyle(.button)
                            .controlSize(.small)
                    }
                }
            }

            if !viewModel.displayRows.isEmpty {
                Section(header: Text("Data Table (\(viewModel.displayRows.count) rows)")) {
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading, spacing: 0) {
                            if viewModel.hasHeader && !viewModel.headers.isEmpty {
                                HStack(spacing: 0) {
                                    ForEach(viewModel.headers, id: \.self) { header in
                                        Text(header)
                                            .font(.caption2.bold())
                                            .padding(6)
                                            .frame(width: 100, alignment: .leading)
                                            .background(Color.accentColor.opacity(0.1))
                                    }
                                }
                            }
                            ForEach(Array(viewModel.displayRows.enumerated()), id: \.offset) { rowIdx, row in
                                HStack(spacing: 0) {
                                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                        Text(cell)
                                            .font(.caption2)
                                            .padding(6)
                                            .frame(width: 100, alignment: .leading)
                                            .background(rowIdx % 2 == 0 ? Color.clear : Color.secondary.opacity(0.05))
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: min(CGFloat(viewModel.displayRows.count + 1) * 32, 300))
                }
            }

            Section(header: Text("Export")) {
                HStack {
                    Button {
                        UIPasteboard.general.string = viewModel.toJSON()
                    } label: {
                        Label("Copy as JSON", systemImage: "curlybraces")
                    }
                    .buttonStyle(.bordered).controlSize(.small)

                    Button {
                        UIPasteboard.general.string = viewModel.input
                    } label: {
                        Label("Copy CSV", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            }
        }
    }
}

class CSVParserViewModel: ObservableObject {
    @Published var input = "id,name,role,score\n1,Alice,Engineer,95\n2,Bob,Designer,88\n3,Charlie,PM,72" {
        didSet { parse() }
    }
    @Published var delimiter = "," { didSet { parse() } }
    @Published var hasHeader = true { didSet { parse() } }
    @Published var filterColumn = -1 { didSet { applyFilterAndSort() } }
    @Published var filterText = "" { didSet { applyFilterAndSort() } }
    @Published var sortColumn = -1 { didSet { applyFilterAndSort() } }
    @Published var sortAscending = true { didSet { applyFilterAndSort() } }
    @Published var headers: [String] = []
    @Published var rows: [[String]] = []
    @Published var displayRows: [[String]] = []

    var rowCount: Int { rows.count }
    var columnCount: Int { headers.isEmpty ? (rows.first?.count ?? 0) : headers.count }
    var cellCount: Int { rows.reduce(0) { $0 + $1.count } }

    private func parse() {
        let lines = input.components(separatedBy: .newlines)
            .map { $0.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: .whitespaces) } }
            .filter { !$0.isEmpty && $0[0] != "" }

        if hasHeader && !lines.isEmpty {
            headers = lines[0]
            rows = Array(lines.dropFirst())
        } else {
            headers = []
            rows = lines
        }
        applyFilterAndSort()
    }

    private func applyFilterAndSort() {
        var result = rows

        if !filterText.isEmpty {
            result = result.filter { row in
                if filterColumn >= 0, filterColumn < row.count {
                    return row[filterColumn].localizedCaseInsensitiveContains(filterText)
                }
                return row.contains { $0.localizedCaseInsensitiveContains(filterText) }
            }
        }

        if sortColumn >= 0 {
            result.sort { a, b in
                guard sortColumn < a.count, sortColumn < b.count else { return false }
                let valA = a[sortColumn]
                let valB = b[sortColumn]
                if let numA = Double(valA), let numB = Double(valB) {
                    return sortAscending ? numA < numB : numA > numB
                }
                return sortAscending ? valA < valB : valA > valB
            }
        }
        displayRows = result
    }

    func toJSON() -> String {
        guard !headers.isEmpty else { return "[]" }
        let dicts: [[String: String]] = rows.map { row in
            var dict: [String: String] = [:]
            for (idx, header) in headers.enumerated() {
                dict[header] = idx < row.count ? row[idx] : ""
            }
            return dict
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dicts, options: .prettyPrinted),
              let str = String(data: data, encoding: .utf8) else { return "[]" }
        return str
    }
}

#Preview {
    CSVParserView()
}
