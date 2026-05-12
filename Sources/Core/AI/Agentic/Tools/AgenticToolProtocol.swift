import Foundation
// import FoundationModels

protocol AgenticToolProtocol {
    var toolName: String { get }
    var toolDescription: String { get }
    var category: String { get }
    var inputSchema: [String: String] { get }
    var producesCode: Bool { get }
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput
}
