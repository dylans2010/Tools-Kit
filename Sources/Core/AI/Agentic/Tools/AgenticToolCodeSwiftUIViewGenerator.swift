import Foundation

struct AgenticToolCodeSwiftUIViewGenerator: AgenticToolProtocol {
    let toolName = "AgenticToolCodeSwiftUIViewGenerator"
    let toolDescription = "Generates a complete SwiftUI view based on requirements."
    let category = "CODE GENERATION SYSTEM"
    let inputSchema = [
        "viewName": "The name of the SwiftUI view",
        "description": "What the view should display and do"
    ]
    let producesCode = true

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        guard let viewName = parameters["viewName"], let description = parameters["description"] else {
            throw NSError(domain: "AgenticToolCodeSwiftUIViewGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing parameters"])
        }

        print("[Agentic] Generating SwiftUI view: \(viewName)")

        let generatedCode = """
import SwiftUI

struct \(viewName): View {
    var body: some View {
        VStack {
            Text("\(viewName)")
                .font(.largeTitle)
            Text("\(description)")
                .padding()
        }
    }
}
"""

        return AgenticToolOutput(
            summary: "Generated SwiftUI view: \(viewName)",
            generatedCode: generatedCode,
            metadata: ["viewName": viewName, "type": "SwiftUI"]
        )
    }
}
