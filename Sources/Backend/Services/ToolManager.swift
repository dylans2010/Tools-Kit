import Foundation

class ToolManager: ObservableObject {
    static let shared = ToolManager()

    @Published var isExecuting = false
    @Published var lastResult: Any?
    @Published var error: Error?

    private init() {}

    func executeTool(_ tool: any Tool) async {
        await MainActor.run {
            isExecuting = true
            error = nil
        }

        do {
            let result = try await tool.execute()
            await MainActor.run {
                lastResult = result
                isExecuting = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                isExecuting = false
            }
        }
    }
}
