import Foundation

enum AgentTaskPriority: Int, Codable, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3

    static func < (lhs: AgentTaskPriority, rhs: AgentTaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
