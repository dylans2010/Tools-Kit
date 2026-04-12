import Foundation

final class CodeDebuggerBackend: ObservableObject {
    @Published var analysis: String = ""
    @Published var isProcessing = false

    func execute(code: String) async throws -> String {
        return try await AIService.shared.generateResponse(prompt: "Debug the following code and provide a list of issues and fixes:\n\n\(code)")
    }

    func debugCode(_ code: String) async {
        await MainActor.run { isProcessing = true }

        // In production, this would call AIService with a specific prompt
        let prompt = "Debug the following code and provide a list of issues and fixes:\n\n\(code)"
        do {
            let response = try await AIService.shared.generateResponse(prompt: prompt)
            await MainActor.run {
                self.analysis = response
                self.isProcessing = false
            }
        } catch {
            await MainActor.run {
                self.analysis = "Error: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
}
