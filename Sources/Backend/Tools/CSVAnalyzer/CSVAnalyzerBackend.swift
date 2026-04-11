import Foundation

struct CSVColumn: Identifiable {
    let id = UUID()
    let name: String
    let values: [String]
    let min: Double?
    let max: Double?
    let mean: Double?
    let nonEmptyCount: Int
}

class CSVAnalyzerBackend: ObservableObject {
    @Published var csvText: String = ""
    @Published var columns: [CSVColumn] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    func analyze() {
        guard !csvText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter CSV data."
            columns = []
            return
        }

        isLoading = true
        errorMessage = ""
        columns = []

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.parseCSV(self.csvText)
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let cols):
                    self.columns = cols
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
        }
    }

    private func parseCSV(_ text: String) -> Result<[CSVColumn], Error> {
        let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count >= 1 else {
            return .failure(NSError(domain: "CSVAnalyzer", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data found."]))
        }

        let header = parseRow(lines[0])
        guard !header.isEmpty else {
            return .failure(NSError(domain: "CSVAnalyzer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not parse header row."]))
        }

        var columnValues: [[String]] = Array(repeating: [], count: header.count)

        for line in lines.dropFirst() {
            let row = parseRow(line)
            for (i, _) in header.enumerated() {
                if i < row.count {
                    columnValues[i].append(row[i])
                } else {
                    columnValues[i].append("")
                }
            }
        }

        let columns: [CSVColumn] = header.enumerated().map { (i, name) in
            let vals = columnValues[i]
            let numericVals = vals.compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            let nonEmpty = vals.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
            return CSVColumn(
                name: name,
                values: vals,
                min: numericVals.min(),
                max: numericVals.max(),
                mean: numericVals.isEmpty ? nil : numericVals.reduce(0, +) / Double(numericVals.count),
                nonEmptyCount: nonEmpty
            )
        }

        return .success(columns)
    }

    private func parseRow(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var chars = Array(line)
        var i = 0

        while i < chars.count {
            let c = chars[i]
            if c == "\"" {
                if inQuotes && i + 1 < chars.count && chars[i + 1] == "\"" {
                    current.append("\"")
                    i += 2
                    continue
                }
                inQuotes.toggle()
            } else if c == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(c)
            }
            i += 1
        }
        fields.append(current)
        return fields
    }
}
