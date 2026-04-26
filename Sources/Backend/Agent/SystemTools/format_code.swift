import Foundation

final class FormatCodeTool: SystemTool {
    let name = "format_code"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let command = (input["command"] as? String) ?? ""
        let arguments = input["arguments"] as? [String] ?? []
        let note = command.isEmpty ? "Execution of shell commands is unavailable on iOS." : "Command '\(command)' recorded for remote execution."
        return successResponse(input: input, context: context, output: [
            "message": note,
            "command": command,
            "arguments": arguments,
            "simulated": true
        ])
    }
}
