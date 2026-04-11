import Foundation
import Combine

protocol ToolExecutable {
    var toolID: String { get }
    func execute(input: [String: Any]) async throws -> [String: Any]
}

class ToolManager: ObservableObject {
    static let shared = ToolManager()
    @Published var runningToolIDs: Set<String> = []

    func execute<T: ToolExecutable>(_ tool: T, input: [String: Any]) async throws -> [String: Any] {
        await MainActor.run { runningToolIDs.insert(tool.toolID) }
        defer { Task { await MainActor.run { self.runningToolIDs.remove(tool.toolID) } } }
        return try await tool.execute(input: input)
    }
}
