import Foundation

enum AgentDemoScriptLibrary {
    static let buildSwiftUIFeature = AgentDemoScript(id: UUID(), name: "Build a SwiftUI Feature", description: "Autonomous SwiftUI feature generation demo.", estimatedDuration: 300, steps: [
        AgentDemoStep(id: UUID(), index: 1, instruction: "Analyze the existing project structure and list all Swift files in the Sources directory"),
        AgentDemoStep(id: UUID(), index: 2, instruction: "Read the main App entry point file and understand the current navigation structure"),
        AgentDemoStep(id: UUID(), index: 3, instruction: "Identify the existing color scheme and design tokens used across the project")
    ], requiredCapabilities: ["tools","codeGeneration"])

    static let debugAndRefactor = AgentDemoScript(id: UUID(), name: "Debug and Refactor", description: "Autonomous refactor diagnosis demo.", estimatedDuration: 300, steps: [AgentDemoStep(id: UUID(), index: 1, instruction: "Search the codebase for all force-unwraps (!) and list them by file")], requiredCapabilities: ["tools"])

    static let fullStackMiniApp = AgentDemoScript(id: UUID(), name: "Full Stack Mini App", description: "Autonomous mini app generation demo.", estimatedDuration: 300, steps: [AgentDemoStep(id: UUID(), index: 1, instruction: "Plan a complete Notes mini-app with CRUD operations, search, and tagging")], requiredCapabilities: ["tools","codeGeneration"])

    static let all: [AgentDemoScript] = [buildSwiftUIFeature, debugAndRefactor, fullStackMiniApp]
}
