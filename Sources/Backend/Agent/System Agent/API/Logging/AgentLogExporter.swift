import Foundation

struct AgentLogExporter {
    func export() async -> Data {
        let logs = await AgentAPILogger.shared.allLogs()
        return (try? JSONEncoder().encode(logs)) ?? Data()
    }
}
