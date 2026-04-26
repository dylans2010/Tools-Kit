import Foundation

struct AgentShortTermMemory {
    private(set) var entries: [String] = []
    var capacity: Int = 10

    mutating func push(_ entry: String) {
        entries.append(entry)
        if entries.count > capacity { entries.removeFirst(entries.count - capacity) }
    }
}
