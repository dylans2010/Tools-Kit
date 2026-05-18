import SwiftUI

struct CSVParserDevTool: DevTool {
    let id = "csv-parser"
    let name = "CSV Parser"
    let category = DevToolCategory.data
    let icon = "tablecells"
    let description = "Parse CSV data into a table"

    func render() -> some View {
        CSVParserView()
    }
}

struct CSVParserView: View {
    @StateObject private var viewModel = CSVParserViewModel()

    var body: some View {
        VStack {
            Form {
                Section("CSV Input") {
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 100)
                        .font(.monospaced(.body)())
                }
            }
            .frame(height: 180)

            if !viewModel.rows.isEmpty {
                List {
                    Section("Parsed Data") {
                        ForEach(0..<viewModel.rows.count, id: \.self) { rowIndex in
                            HStack {
                                ForEach(0..<viewModel.rows[rowIndex].count, id: \.self) { colIndex in
                                    Text(viewModel.rows[rowIndex][colIndex])
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
            } else {
                Spacer()
                Text("No data to display")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}

class CSVParserViewModel: ObservableObject {
    @Published var inputText = "Name,Age,Role\nAlice,30,Engineer\nBob,25,Designer" {
        didSet {
            parse()
        }
    }
    @Published var rows: [[String]] = []

    init() {
        parse()
    }

    private func parse() {
        let lines = inputText.components(separatedBy: .newlines)
        rows = lines.filter { !$0.isEmpty }.map { $0.components(separatedBy: ",") }
    }
}
