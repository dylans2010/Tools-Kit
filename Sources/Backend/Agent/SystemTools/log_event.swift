import Foundation

final class LogEventTool: SystemTool {
    let name = "log_event"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileName = "agent_timeline.json"
        var timeline = loadJSONArray(fileName: fileName)
        if name == "event_replay" || name == "execution_trace_export" {
            return successResponse(input: input, context: context, output: ["events": timeline, "count": timeline.count])
        }
        let event: [String: Any] = [
            "tool": name,
            "message": (input["message"] as? String) ?? "",
            "payload": input,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        timeline.append(event)
        try storeJSON(timeline, fileName: fileName)
        return successResponse(input: input, context: context, output: ["logged": true, "events_count": timeline.count])
    }
}
