import Foundation
import Combine

enum AgenticExecutionStatus: String, Codable {
    case preparing
    case running
    case completed
    case failed
}

struct AgenticExecutionTrace: Identifiable, Codable {
    let id: UUID
    let toolName: String
    let parameters: [String: String]
    var status: AgenticExecutionStatus
    var output: AgenticToolOutput?
    var error: String?
    let timestamp: Date

    init(toolName: String, parameters: [String: String]) {
        self.id = UUID()
        self.toolName = toolName
        self.parameters = parameters
        self.status = .preparing
        self.timestamp = Date()
    }
}

@MainActor
final class AgenticExecutionTraceStore: ObservableObject {
    static let shared = AgenticExecutionTraceStore()

    @Published var traces: [AgenticExecutionTrace] = []

    private init() {}

    func addTrace(_ trace: AgenticExecutionTrace) {
        traces.append(trace)
    }

    func updateTrace(id: UUID, status: AgenticExecutionStatus, output: AgenticToolOutput? = nil, error: String? = nil) {
        if let index = traces.firstIndex(where: { $0.id == id }) {
            traces[index].status = status
            if let output = output {
                traces[index].output = output
            }
            if let error = error {
                traces[index].error = error
            }
        }
    }

    func clear() {
        traces = []
    }
}
