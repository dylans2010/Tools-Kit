import Foundation

final class EventReplayTool: SystemTool {
    let name = "event_replay"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
