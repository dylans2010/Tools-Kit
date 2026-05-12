import Foundation
import FoundationModels

struct AgenticToolSheetAnalyzer: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "sheet_analyzer",
        description: "Analyze spreadsheet data for patterns and statistics",
        category: "spreadsheet",
        inputSchema: ["sheetId": "String", "analysisType": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let sheetIdStr = parameters["sheetId"] ?? ""
        let analysisType = parameters["analysisType"] ?? "summary"

        guard let sheetId = UUID(uuidString: sheetIdStr) else {
            throw AgenticToolExecutionError.executionFailed("sheet_analyzer", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid sheet ID"]))
        }

        let manager = SpreadsheetsManager.shared
        guard let sheet = manager.spreadsheets.first(where: { $0.id == sheetId }) else {
            throw AgenticToolExecutionError.executionFailed("sheet_analyzer", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sheet not found"]))
        }

        let cellData = sheet.cells.prefix(50).map { row in
            row.map { $0.value }.joined(separator: "\t")
        }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: "You are a data analysis AI. Analyze spreadsheet data and provide detailed statistical insights.")
        let prompt = """
        Analyze this spreadsheet: '\(sheet.name)'
        Analysis type: \(analysisType)
        Rows: \(sheet.cells.count), Columns: \(sheet.cells.first?.count ?? 0)
        Data:
        \(cellData)

        Provide: statistics, patterns, outliers, trends, and actionable insights.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Analyzed '\(sheet.name)' (\(analysisType)): \(sheet.cells.count) rows",
            generatedCode: nil,
            metadata: ["sheetId": sheetIdStr, "analysisType": analysisType, "rowCount": "\(sheet.cells.count)"],
            dataPayload: ["analysis": response.content]
        )
    }
}
