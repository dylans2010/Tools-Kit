import Foundation

final class CreateCheckpointTool: SystemTool {
    let name = "create_checkpoint"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileName = "agent_state.json"
        var state = loadJSONDictionary(fileName: fileName)
        state[name] = input
        state["updated_at"] = ISO8601DateFormatter().string(from: Date())
        try storeJSON(state, fileName: fileName)
        return successResponse(input: input, context: context, output: ["state_updated": true, "tool": name])
    }
}
