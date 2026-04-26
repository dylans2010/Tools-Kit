import Foundation

enum AgentTaskPriority: Int, Codable, Comparable {
    case low = 0, normal = 1, high = 2, critical = 3

    static func < (lhs: AgentTaskPriority, rhs: AgentTaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
