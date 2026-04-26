import Foundation

final class SchemaValidationTool: SystemTool {
    let name = "schema_validation"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileURL = try resolveFileURL(from: input)
        let requiredFields = input["required_fields"] as? [String] ?? []
        let data = try Data(contentsOf: fileURL)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SystemToolError(message: "Schema validation currently supports top-level JSON objects.", code: "invalid_payload")
        }
        let missing = requiredFields.filter { object[$0] == nil }

        return successResponse(input: input, context: context, output: [
            "path": fileURL.path,
            "required_fields": requiredFields,
            "missing_fields": missing,
            "valid": missing.isEmpty
        ])
    }
}
