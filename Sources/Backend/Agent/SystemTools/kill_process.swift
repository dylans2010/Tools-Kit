import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

final class KillProcessTool: SystemTool {
    let name = "kill_process"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        guard let pid = input["pid"] as? Int32 else {
            throw SystemToolError.missingParameter("pid")
        }
        let signal = (input["signal"] as? Int32) ?? SIGTERM
        let result = kill(pid, signal)
        if result != 0 {
            throw SystemToolError(message: String(cString: strerror(errno)), code: "kill_failed")
        }
        return successResponse(input: input, context: context, output: [
            "pid": Int(pid),
            "signal": Int(signal),
            "terminated": true
        ])
    }
}
