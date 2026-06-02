import SwiftUI

struct GraphQLSchemaExplorerDevTool: DevTool {
    let id = "graphql-schema-explorer"
    let name = "GraphQL Schema Explorer"
    let category: DevToolCategory = .data
    let icon = "diamond.fill"
    let description = "Visualize and explore GraphQL schema definitions"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste GraphQL Schema (SDL)") { input in
            let types = input.components(separatedBy: "type ").count - 1
            let queries = input.components(separatedBy: "query").count - 1
            return "Analysis:\nTypes Found: \(types)\nPotential Queries: \(queries)\nReady for introspection."
        }
    }
}
