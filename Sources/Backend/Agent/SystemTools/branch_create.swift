import Foundation

final class BranchCreateTool: SystemTool {
    let name = "branch_create"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        var state = loadJSONDictionary(fileName: "agent_git_state.json")
        var branches = state["branches"] as? [String] ?? ["main"]
        var current = state["current"] as? String ?? "main"
        switch name {
        case "branch_create":
            let branch = try requireString(input, key: "branch")
            if !branches.contains(branch) { branches.append(branch) }
            current = branch
            state["last_action"] = "created"
            state["message"] = "Created branch \(branch)"
        case "branch_switch":
            let branch = try requireString(input, key: "branch")
            if !branches.contains(branch) { throw SystemToolError(message: "Branch not found: \(branch)", code: "branch_not_found") }
            current = branch
            state["last_action"] = "switched"
        case "merge_branch":
            let branch = try requireString(input, key: "branch")
            if !branches.contains(branch) { throw SystemToolError(message: "Branch not found: \(branch)", code: "branch_not_found") }
            state["last_merge"] = ["from": branch, "into": current, "timestamp": ISO8601DateFormatter().string(from: Date())]
        case "revert_commit":
            state["last_revert"] = (input["commit"] as? String) ?? "HEAD"
        case "commit_changes":
            state["last_commit_message"] = (input["message"] as? String) ?? "Agent commit"
            state["last_commit_at"] = ISO8601DateFormatter().string(from: Date())
        default:
            break
        }
        state["branches"] = branches
        state["current"] = current
        try storeJSON(state, fileName: "agent_git_state.json")
        return successResponse(input: input, context: context, output: state)
    }
}
