import SwiftUI

struct ReminderGeneratorView: View {
    @State private var topic = ""
    @State private var reminders: [String] = []
    @State private var isGenerating = false
    @State private var error: String?

    private let aiService = AIService()

    var body: some View {
        VStack {
            TextField("What are you planning? (e.g. Travel to Japan)", text: $topic)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button(action: {
                Task {
                    await generate()
                }
            }) {
                if isGenerating {
                    ProgressView().tint(.white)
                } else {
                    Text("Generate Reminders")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(topic.isEmpty || isGenerating)

            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }

            List(reminders, id: \.self) { reminder in
                Label(reminder, systemImage: "bell")
            }
        }
        .navigationTitle("Smart Reminders")
    }

    private func generate() async {
        guard !topic.isEmpty else { return }

        isGenerating = true
        error = nil

        let prompt = """
        Extract tasks from the following input and return them as a JSON array of objects with 'title', 'description', 'priority' (Low, Medium, High), and 'dueDate' (ISO8601 string or null).

        Input: \(topic)
        """

        let request = AIRequest(
            prompt: prompt,
            systemPrompt: "You are a structured task extractor. Return ONLY valid JSON.",
            model: "google/gemini-2.0-flash-exp:free",
            attachments: nil
        )

        do {
            let result = try await aiService.process(request: request)

            // Basic extraction of JSON block if AI wraps it in markdown
            let jsonString = result.components(separatedBy: "```json").last?.components(separatedBy: "```").first ?? result

            if let data = jsonString.data(using: .utf8),
               let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {

                let extractedReminders = jsonArray.compactMap { dict -> String? in
                    let title = dict["title"] as? String ?? ""
                    let priority = dict["priority"] as? String ?? "Medium"
                    return "[\(priority)] \(title)"
                }

                await MainActor.run {
                    self.reminders = extractedReminders.isEmpty ? [result] : extractedReminders
                    isGenerating = false
                }
            } else {
                await MainActor.run {
                    self.reminders = [result]
                    isGenerating = false
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isGenerating = false
            }
        }
    }
}

struct ReminderGeneratorTool: Tool {
    let name = "Smart Reminders"
    let icon = "bell.badge.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "Automatically generate a list of reminders for any task or event"
    let requiresAPI = true
    var view: AnyView { AnyView(ReminderGeneratorView()) }
}
