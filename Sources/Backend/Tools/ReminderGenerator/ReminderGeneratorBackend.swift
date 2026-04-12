import Foundation

final class ReminderGeneratorBackend: ObservableObject {
    @Published var reminders: [String] = []
    @Published var isProcessing = false

    func generateReminders(from text: String) async {
        await MainActor.run { isProcessing = true }
        let prompt = "Extract specific action items and reminders from this text as a list:\n\n\(text)"
        do {
            let response = try await AIService.shared.generateResponse(prompt: prompt)
            await MainActor.run {
                self.reminders = response.components(separatedBy: "\n").filter { !$0.isEmpty }
                self.isProcessing = false
            }
        } catch {
            await MainActor.run { isProcessing = false }
        }
    }
}
