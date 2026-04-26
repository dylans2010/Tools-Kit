import Foundation

struct AgentAutomationScheduler {
    func nextRunDate(interval: TimeInterval, from date: Date = Date()) -> Date {
        date.addingTimeInterval(max(interval, 0))
    }
}
