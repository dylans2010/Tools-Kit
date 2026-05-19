import SwiftUI

struct CSVParserDevTool: DevTool {
    let id = "csv-parser"
    let name = "CSV Parser"
    let category = DevToolCategory.data
    let icon = "tablecells"
    let description = "Parse CSV data into structured tables"

    func render() -> some View {
        CSVParserView()
    }
}

struct CSVParserView: View {
    @StateObject private var viewModel = CSVParserViewModel()
    @State private var showingExport = false

    var body: some View {
        List {
            Section("Source Data") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 120)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    if !viewModel.input.isEmpty {
                        Button { viewModel.input = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }

                HStack {
                    Button("Import File") { /* Implementation would use fileImporter */ }
                        .buttonStyle(.bordered).controlSize(.small)
                    Spacer()
                    Button("Sample Data") { viewModel.loadSample() }
                        .buttonStyle(.bordered).controlSize(.small)
                }
            }

            Section("Parsing Options") {
                HStack {
                    Text("Delimiter").font(.caption.bold())
                    Spacer()
                    TextField(",", text: $viewModel.delimiter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                }
                Toggle("Treat first row as header", isOn: $viewModel.hasHeader)
                Toggle("Trim whitespace", isOn: $viewModel.trimWhitespace)
            }

            if !viewModel.rows.isEmpty {
                Section("Preview (\(viewModel.rows.count) rows)") {
                    ScrollView([.horizontal, .vertical]) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<viewModel.rows.count, id: \.self) { rowIndex in
                                HStack(spacing: 0) {
                                    ForEach(0..<viewModel.rows[rowIndex].count, id: \.self) { colIndex in
                                        Text(viewModel.rows[rowIndex][colIndex])
                                            .font(.system(size: 10, design: .monospaced))
                                            .padding(8)
                                            .frame(width: 120, height: 34, alignment: .leading)
                                            .background(rowIndex == 0 && viewModel.hasHeader ? Color.blue.opacity(0.1) : Color.clear)
                                            .border(Color.gray.opacity(0.2), lineWidth: 0.5)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 240)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }

                Section {
                    Button {
                        viewModel.exportAsJSON()
                    } label: {
                        Label("Export as JSON Array", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("CSV Lab")
    }
}

class CSVParserViewModel: ObservableObject {
    @Published var input = "id,name,role\n1,Jules,Engineer\n2,Alice,Designer" {
        didSet { parse() }
    }
    @Published var delimiter = "," {
        didSet { parse() }
    }
    @Published var hasHeader = true {
        didSet { parse() }
    }
    @Published var trimWhitespace = true {
        didSet { parse() }
    }
    @Published var rows: [[String]] = []

    func loadSample() {
        input = "timestamp,event,status,latency\n1625097600,SDK_INIT,SUCCESS,42ms\n1625097605,AUTH_REQ,SUCCESS,120ms\n1625097610,DATA_SYNC,RETRY,450ms\n1625097615,UI_RENDER,SUCCESS,18ms"
    }

    private func parse() {
        let lines = input.components(separatedBy: .newlines)
        rows = lines.compactMap { line in
            let cells = line.components(separatedBy: delimiter)
            let processed = cells.map { trimWhitespace ? $0.trimmingCharacters(in: .whitespaces) : $0 }
            return processed.allSatisfy({ $0.isEmpty }) ? nil : processed
        }
    }

    func exportAsJSON() {
        guard !rows.isEmpty else { return }
        var result: [[String: String]] = []
        let headers = hasHeader ? rows[0] : (0..<rows[0].count).map { "column_\($0)" }
        let dataRows = hasHeader ? Array(rows.dropFirst()) : rows

        for row in dataRows {
            var dict: [String: String] = [:]
            for (i, cell) in row.enumerated() {
                if i < headers.count {
                    dict[headers[i]] = cell
                }
            }
            result.append(dict)
        }

        if let data = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            let av = UIActivityViewController(activityItems: [jsonString], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.first?.rootViewController?.present(av, animated: true)
            }
        }
    }
}

#Preview {
    CSVParserView()
}
