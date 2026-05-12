import Foundation

struct AgenticToolSheetDependencyResolver: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "sheet_dependency_resolver",
        description: "Resolve formula dependencies in a spreadsheet",
        category: "spreadsheet",
        inputSchema: ["sheetId": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let sheetIdStr = parameters["sheetId"] ?? ""

        guard let sheetId = UUID(uuidString: sheetIdStr) else {
            throw AgenticToolExecutionError.executionFailed("sheet_dependency_resolver", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid sheet ID"]))
        }

        let manager = SpreadsheetsManager.shared
        guard let sheet = manager.spreadsheets.first(where: { $0.id == sheetId }) else {
            throw AgenticToolExecutionError.executionFailed("sheet_dependency_resolver", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sheet not found"]))
        }

        var dependencies: [String: [String]] = [:]
        var formulaCells: [String] = []

        for (rowIdx, row) in sheet.cells.enumerated() {
            for (colIdx, cell) in row.enumerated() {
                let cellRef = "\(Character(UnicodeScalar(65 + colIdx)!))\(rowIdx + 1)"
                if cell.value.hasPrefix("=") {
                    formulaCells.append(cellRef)
                    dependencies[cellRef] = extractReferences(from: cell.value)
                }
            }
        }

        var payload: [String: String] = [
            "formulaCellCount": "\(formulaCells.count)",
            "totalCells": "\(sheet.cells.flatMap { $0 }.count)"
        ]
        for (cell, deps) in dependencies {
            payload["deps_\(cell)"] = deps.joined(separator: ", ")
        }

        return AgenticToolOutput(
            summary: "Resolved dependencies for \(formulaCells.count) formula cells in '\(sheet.name)'",
            generatedCode: nil,
            metadata: ["sheetId": sheetIdStr, "formulaCells": "\(formulaCells.count)"],
            dataPayload: payload
        )
    }

    private func extractReferences(from formula: String) -> [String] {
        let pattern = "[A-Z]+[0-9]+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: formula, range: NSRange(formula.startIndex..., in: formula))
        return matches.compactMap { match in
            Range(match.range, in: formula).map { String(formula[$0]) }
        }
    }
}
