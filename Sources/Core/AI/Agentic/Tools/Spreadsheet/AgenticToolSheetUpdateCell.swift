import Foundation

struct AgenticToolSheetUpdateCell: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "sheet_update_cell",
        description: "Update a cell value",
        category: "spreadsheet",
        inputSchema: ["sheetId": "String", "row": "String", "column": "String", "value": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let sheetIdStr = parameters["sheetId"] ?? ""
        let rowStr = parameters["row"] ?? "0"
        let columnStr = parameters["column"] ?? "0"
        let value = parameters["value"] ?? ""

        guard let sheetId = UUID(uuidString: sheetIdStr) else {
            throw AgenticToolExecutionError.executionFailed("sheet_update_cell", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid sheet ID"]))
        }

        let row = Int(rowStr) ?? 0
        let column = Int(columnStr) ?? 0
        let manager = SpreadsheetsManager.shared

        guard var sheet = manager.spreadsheets.first(where: { $0.id == sheetId }) else {
            throw AgenticToolExecutionError.executionFailed("sheet_update_cell", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sheet not found"]))
        }

        while sheet.cells.count <= row {
            sheet.cells.append([])
        }
        while sheet.cells[row].count <= column {
            sheet.cells[row].append(SpreadsheetCell())
        }

        sheet.cells[row][column].value = value
        if value.hasPrefix("=") {
            sheet.cells[row][column].formula = value
        }
        manager.updateSpreadsheet(sheet)

        return AgenticToolOutput(
            summary: "Updated cell [\(row),\(column)] in '\(sheet.name)' to '\(value)'",
            generatedCode: nil,
            metadata: ["sheetId": sheetIdStr, "row": rowStr, "column": columnStr],
            dataPayload: ["value": value]
        )
    }
}
