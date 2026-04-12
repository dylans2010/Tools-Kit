import Foundation

final class SchemaGeneratorBackend: ObservableObject {
    @Published var schema: String = ""
    @Published var isProcessing = false

    func generateSchema(from description: String, format: String) async {
        await MainActor.run { isProcessing = true }
        let prompt = "Generate a \(format) schema for the following database/data structure description:\n\n\(description)"
        do {
            let response = try await AIService.shared.generateResponse(prompt: prompt)
            await MainActor.run {
                self.schema = response
                self.isProcessing = false
            }
        } catch {
            await MainActor.run { isProcessing = false }
        }
    }
}
