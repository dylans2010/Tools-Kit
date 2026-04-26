import Foundation

struct AgentPerformanceTracker {
    private(set) var samples: [TimeInterval] = []

    mutating func record(_ value: TimeInterval) { samples.append(value) }
    var average: TimeInterval { samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count) }
}
