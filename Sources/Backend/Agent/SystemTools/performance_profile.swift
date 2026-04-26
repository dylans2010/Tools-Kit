import Foundation

final class PerformanceProfileTool: SystemTool {
    let name = "performance_profile"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileURL = try resolveFileURL(from: input)
        let iterations = max(1, input["iterations"] as? Int ?? 25)
        var samples: [Double] = []
        samples.reserveCapacity(iterations)

        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            _ = try Data(contentsOf: fileURL)
            let end = CFAbsoluteTimeGetCurrent()
            samples.append((end - start) * 1000)
        }

        let total = samples.reduce(0, +)
        let avg = total / Double(samples.count)
        let minValue = samples.min() ?? 0
        let maxValue = samples.max() ?? 0

        return successResponse(input: input, context: context, output: [
            "path": fileURL.path,
            "iterations": iterations,
            "average_ms": avg,
            "min_ms": minValue,
            "max_ms": maxValue
        ])
    }
}
