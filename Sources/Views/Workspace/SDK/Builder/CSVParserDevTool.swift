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

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "CSV Parser",
                description: "Convert comma-separated values into interactive data tables with custom delimiter support.",
                icon: "tablecells"
            )
            .padding()

            Form {
                Section("Input CSV") {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 120)
                        .font(.system(.caption, design: .monospaced))
                }

                Section("Configuration") {
                    HStack {
                        TextField("Delimiter", text: $viewModel.delimiter)
                            .frame(width: 80)
                        Toggle("Has Header", isOn: $viewModel.hasHeader)
                    }
                }

                if !viewModel.rows.isEmpty {
                    Section("Data Table") {
                        ScrollView(.horizontal) {
                            VStack(alignment: .leading) {
                                ForEach(viewModel.rows, id: \.self) { row in
                                    HStack {
                                        ForEach(row, id: \.self) { cell in
                                            Text(cell)
                                                .font(.caption2)
                                                .padding(4)
                                                .frame(width: 100, alignment: .leading)
                                                .border(Color.secondary.opacity(0.2))
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                    }
                }
            }
        }
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
    @Published var rows: [[String]] = []

    private func parse() {
        let lines = input.components(separatedBy: .newlines)
        rows = lines.map { $0.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: .whitespaces) } }
                    .filter { !$0.isEmpty && $0[0] != "" }
    }
}
