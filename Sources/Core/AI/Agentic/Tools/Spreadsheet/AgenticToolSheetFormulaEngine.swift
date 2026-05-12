import Foundation
import FoundationModels

struct AgenticToolSheetFormulaEngine: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "sheet_formula_engine",
        description: "Evaluate or create formulas",
        category: "spreadsheet",
        inputSchema: ["sheetId": "String", "formula": "String", "targetCell": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let sheetIdStr = parameters["sheetId"] ?? ""
        let formula = parameters["formula"] ?? ""
        let targetCell = parameters["targetCell"] ?? "A1"

        guard let sheetId = UUID(uuidString: sheetIdStr) else {
            throw AgenticToolExecutionError.executionFailed("sheet_formula_engine", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid sheet ID"]))
        }

        let manager = SpreadsheetsManager.shared
        guard let sheet = manager.spreadsheets.first(where: { $0.id == sheetId }) else {
            throw AgenticToolExecutionError.executionFailed("sheet_formula_engine", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sheet not found"]))
        }

        let cellData = sheet.cells.prefix(20).map { row in
            row.map { $0.value }.joined(separator: "\t")
        }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: "You are a spreadsheet formula engine. Evaluate formulas against provided data and return results.")
        let prompt = """
        Sheet: \(sheet.name)
        Formula: \(formula)
        Target cell: \(targetCell)
        Data:
        \(cellData)

        Evaluate this formula and provide the result. If it's a creation request, generate the appropriate formula.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Evaluated formula '\(formula)' in '\(sheet.name)' at \(targetCell)",
            generatedCode: nil,
            metadata: ["sheetId": sheetIdStr, "formula": formula, "targetCell": targetCell],
            dataPayload: ["result": response.content]
        )
    }
}
