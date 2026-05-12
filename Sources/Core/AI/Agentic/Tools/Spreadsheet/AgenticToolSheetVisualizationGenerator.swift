import Foundation
import FoundationModels

struct AgenticToolSheetVisualizationGenerator: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "sheet_visualization_generator",
        description: "Generate chart/visualization from sheet data",
        category: "spreadsheet",
        inputSchema: ["sheetId": "String", "chartType": "String", "dataRange": "String"],
        producesCode: true
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let sheetIdStr = parameters["sheetId"] ?? ""
        let chartType = parameters["chartType"] ?? "bar"
        let dataRange = parameters["dataRange"] ?? "all"

        guard let sheetId = UUID(uuidString: sheetIdStr) else {
            throw AgenticToolExecutionError.executionFailed("sheet_visualization_generator", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid sheet ID"]))
        }

        let manager = SpreadsheetsManager.shared
        guard let sheet = manager.spreadsheets.first(where: { $0.id == sheetId }) else {
            throw AgenticToolExecutionError.executionFailed("sheet_visualization_generator", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sheet not found"]))
        }

        let session = LanguageModelSession(instructions: "You are a SwiftUI Charts code generator. Generate complete, compilable Swift code using the Charts framework.")
        let prompt = """
        Generate a SwiftUI Charts view for this data:
        Sheet: \(sheet.name)
        Chart type: \(chartType)
        Data range: \(dataRange)
        Rows: \(sheet.cells.count)

        Generate complete Swift code including imports, data model, and Chart view.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Generated \(chartType) chart for '\(sheet.name)'",
            generatedCode: response.content,
            metadata: ["sheetId": sheetIdStr, "chartType": chartType, "dataRange": dataRange],
            dataPayload: ["chartType": chartType]
        )
    }
}
