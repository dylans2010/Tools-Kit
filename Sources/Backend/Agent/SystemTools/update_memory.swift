import Foundation

final class UpdateMemoryTool: SystemTool {
    let name = "update_memory"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileName = "agent_memory.json"
        var memory = loadJSONArray(fileName: fileName)
        switch name {
        case "clear_memory":
            memory.removeAll()
            try storeJSON(memory, fileName: fileName)
            return successResponse(input: input, context: context, output: ["cleared": true])
        case "save_memory":
            let key = try requireString(input, key: "key")
            let value = try requireString(input, key: "value")
            memory.append(["key": key, "value": value, "updated_at": ISO8601DateFormatter().string(from: Date())])
            try storeJSON(memory, fileName: fileName)
            return successResponse(input: input, context: context, output: ["saved": true, "count": memory.count])
        case "update_memory":
            let key = try requireString(input, key: "key")
            let value = try requireString(input, key: "value")
            memory.removeAll { ($0["key"] as? String) == key }
            memory.append(["key": key, "value": value, "updated_at": ISO8601DateFormatter().string(from: Date())])
            try storeJSON(memory, fileName: fileName)
            return successResponse(input: input, context: context, output: ["updated": true, "key": key])
        case "load_memory":
            if let key = input["key"] as? String {
                let items = memory.filter { ($0["key"] as? String) == key }
                return successResponse(input: input, context: context, output: ["items": items])
            }
            return successResponse(input: input, context: context, output: ["items": memory])
        default:
            let summary = memory.prefix(20).map { "\(($0["key"] as? String) ?? "?"): \(($0["value"] as? String) ?? "")" }.joined(separator: "\n")
            return successResponse(input: input, context: context, output: ["summary": summary, "count": memory.count])
        }
    }
}
