import Foundation
import Combine

final class SpreadsheetsManager: ObservableObject {
    static let shared = SpreadsheetsManager()

    @Published var spreadsheets: [Spreadsheet] = []
    private let aiService = AIService.shared
    private let aiDecoder = AIResponseDecoder()

    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Spreadsheets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func fileURL(for id: UUID) -> URL {
        saveDir.appendingPathComponent("\(id.uuidString).json")
    }

    private var indexURL: URL {
        saveDir.appendingPathComponent("index.json")
    }

    private init() { load() }

    // MARK: - CRUD

    @discardableResult
    func createSpreadsheet(name: String = "Untitled Spreadsheet") -> Spreadsheet {
        let sheet = Spreadsheet.empty(name: name)
        spreadsheets.insert(sheet, at: 0)
        save(sheet)
        saveIndex()
        return sheet
    }

    func updateSpreadsheet(_ sheet: Spreadsheet) {
        if let idx = spreadsheets.firstIndex(where: { $0.id == sheet.id }) {
            var updated = sheet
            updated.updatedAt = Date()
            spreadsheets[idx] = updated
            save(updated)
        }
    }

    func deleteSpreadsheet(_ sheet: Spreadsheet) {
        spreadsheets.removeAll { $0.id == sheet.id }
        try? FileManager.default.removeItem(at: fileURL(for: sheet.id))
        saveIndex()
    }

    // MARK: - Formula Engine

    func compute(cell: SpreadsheetCell, allCells: [[SpreadsheetCell]]) -> String {
        guard let formula = cell.formula, formula.hasPrefix("=") else {
            return cell.value
        }
        let expr = String(formula.dropFirst()).trimmingCharacters(in: .whitespaces).uppercased()
        if expr.hasPrefix("SUM(") {
            return computeRange(expr: expr, function: "SUM", cells: allCells)
        } else if expr.hasPrefix("AVERAGE(") {
            return computeRange(expr: expr, function: "AVERAGE", cells: allCells)
        }
        return "#ERR"
    }

    private func computeRange(expr: String, function fname: String, cells: [[SpreadsheetCell]]) -> String {
        // Parse range like A1:C3
        let inner = expr
            .replacingOccurrences(of: "\(fname)(", with: "")
            .replacingOccurrences(of: ")", with: "")
        let parts = inner.split(separator: ":").map { String($0).trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let (startCol, startRow) = parseCell(parts[0]),
              let (endCol, endRow) = parseCell(parts[1]) else { return "#ERR" }

        var values: [Double] = []
        for row in startRow...min(endRow, cells.count - 1) {
            for col in startCol...min(endCol, (cells[row].count) - 1) {
                let val = cells[row][col].value
                if let d = Double(val) { values.append(d) }
            }
        }
        if values.isEmpty { return "0" }
        switch fname {
        case "SUM": return formatNumber(values.reduce(0, +))
        case "AVERAGE": return formatNumber(values.reduce(0, +) / Double(values.count))
        default: return "#ERR"
        }
    }

    private func parseCell(_ ref: String) -> (Int, Int)? {
        // e.g. "A1" → (col: 0, row: 0)
        let letters = ref.prefix(while: { $0.isLetter })
        let digits = ref.dropFirst(letters.count)
        guard let col = columnIndex(String(letters)),
              let row = Int(digits), row >= 1 else { return nil }
        return (col, row - 1)
    }

    private func columnIndex(_ s: String) -> Int? {
        let upper = s.uppercased()
        var result = 0
        for char in upper {
            guard let ascii = char.asciiValue else { return nil }
            result = result * 26 + Int(ascii - 64)
        }
        return result - 1
    }

    private func formatNumber(_ d: Double) -> String {
        d == d.rounded() ? String(Int(d)) : String(format: "%.2f", d)
    }

    // MARK: - Persistence

    private func save(_ sheet: Spreadsheet) {
        if let data = try? JSONEncoder().encode(sheet) {
            try? data.write(to: fileURL(for: sheet.id))
        }
    }

    private func saveIndex() {
        let ids = spreadsheets.map { $0.id.uuidString }
        if let data = try? JSONEncoder().encode(ids) {
            try? data.write(to: indexURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return
        }
        spreadsheets = ids.compactMap { idStr -> Spreadsheet? in
            guard let uuid = UUID(uuidString: idStr),
                  let data = try? Data(contentsOf: fileURL(for: uuid)),
                  let sheet = try? JSONDecoder().decode(Spreadsheet.self, from: data) else { return nil }
            return sheet
        }
    }

    // MARK: - AI Analysis

    struct SpreadsheetAIPayload: Codable {
        let summary: String
        let formulaSuggestions: [String]
        let columnTypes: [String]
        let rangeInsights: [String]
        let chartSuggestions: [String]
    }

    private var aiSchemaString: String {
        """
        {
          "type": "object",
          "required": ["summary", "formulaSuggestions", "columnTypes", "rangeInsights", "chartSuggestions"],
          "properties": {
            "summary": { "type": "string" },
            "formulaSuggestions": { "type": "array", "items": { "type": "string" } },
            "columnTypes": { "type": "array", "items": { "type": "string" } },
            "rangeInsights": { "type": "array", "items": { "type": "string" } },
            "chartSuggestions": { "type": "array", "items": { "type": "string" } }
          }
        }
        """
    }

    private var aiSchema: AIJSONType {
        .object([
            "summary": .string,
            "formulaSuggestions": .array(.string),
            "columnTypes": .array(.string),
            "rangeInsights": .array(.string),
            "chartSuggestions": .array(.string)
        ])
    }

    @MainActor
    func analyzeSpreadsheet(prompt: String, dataPreview: String) async throws -> SpreadsheetAIPayload {
        // Drive spreadsheet insights and formula generation from validated JSON.
        let request = """
        User request:
        \(prompt)

        Spreadsheet data sample:
        \(dataPreview)
        """
        let json = try await aiService.generateStructuredJSON(
            prompt: request,
            jsonSchema: aiSchemaString,
            preferredModel: "openrouter/free",
            systemPrompt: "You are a spreadsheet analyst. Return strict JSON only."
        )
        return try aiDecoder.decode(SpreadsheetAIPayload.self, from: json, schema: aiSchema)
    }
}
