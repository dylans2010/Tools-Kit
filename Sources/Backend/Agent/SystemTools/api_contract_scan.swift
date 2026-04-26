import Foundation

final class ApiContractScanTool: SystemTool {
    let name = "api_contract_scan"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileURL = try resolveFileURL(from: input)
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let expected = (input["expected_endpoints"] as? [String]) ?? []

        let discovered = content
            .components(separatedBy: .newlines)
            .compactMap { line -> String? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("/") else { return nil }
                return trimmed.components(separatedBy: " ").first
            }

        let missing = expected.filter { endpoint in
            !discovered.contains(where: { $0 == endpoint })
        }

        return successResponse(input: input, context: context, output: [
            "file": fileURL.path,
            "discovered_endpoints": discovered,
            "expected_endpoints": expected,
            "missing_endpoints": missing,
            "contract_ok": missing.isEmpty
        ])
    }
}
