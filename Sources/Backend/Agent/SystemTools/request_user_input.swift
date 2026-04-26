import Foundation

final class RequestUserInputTool: SystemTool {
    let name = "request_user_input"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let prompt = try requireString(input, key: "prompt")
        let options = input["options"] as? [String] ?? []
        let requestId = UUID().uuidString
        var pending = loadJSONArray(fileName: "agent_pending_user_requests.json")
        pending.append([
            "request_id": requestId,
            "session_id": context.sessionId,
            "workspace_id": context.workspaceId,
            "prompt": prompt,
            "options": options,
            "created_at": context.timestamp,
            "status": "pending"
        ])
        try storeJSON(pending, fileName: "agent_pending_user_requests.json")

        return successResponse(input: input, context: context, output: [
            "request_id": requestId,
            "prompt": prompt,
            "options": options,
            "status": "pending"
        ])
    }
}
