import Foundation

struct AgenticToolSheetCreate: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "sheet_create",
        description: "Create a new spreadsheet",
        category: "spreadsheet",
        inputSchema: ["name": "String", "columns": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let name = parameters["name"] ?? "Untitled Sheet"
        let columnsStr = parameters["columns"] ?? "A,B,C"
        let columns = columnsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        let manager = SpreadsheetsManager.shared
        var sheet = manager.createSpreadsheet(name: name)

        for (colIdx, header) in columns.enumerated() where colIdx < (sheet.cells.first?.count ?? 0) {
            sheet.cells[0][colIdx].value = header
        }

        manager.updateSpreadsheet(sheet)

        return AgenticToolOutput(
            summary: "Created spreadsheet '\(name)' with \(columns.count) columns",
            generatedCode: nil,
            metadata: ["sheetId": sheet.id.uuidString, "columnCount": "\(columns.count)"],
            dataPayload: ["name": name, "columns": columnsStr]
        )
    }
}
