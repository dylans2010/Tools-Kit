import SwiftUI

struct ReminderGeneratorView: View {
    @State private var topic = ""
    @State private var reminders: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let aiService = AIService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextField("What are you planning? (e.g. Travel to Japan)", text: $topic)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button(action: { Task { await generate() } }) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Generate Reminders")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(topic.isEmpty || isLoading)

                if let error = errorMessage {
                    Text(error).foregroundColor(.red).font(.caption).padding()
                }

                if !reminders.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Generated Reminders", systemImage: "bell.badge.fill")
                            .font(.headline)

                        Text(reminders)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Smart Reminders")
    }

    private func generate() async {
        isLoading = true
        errorMessage = nil
        do {
            reminders = try await aiService.generateReminders(topic: topic)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct ReminderGeneratorTool: Tool {
    let id = UUID()
    let name = "Smart Reminders"
    let icon = "bell.badge.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "Automatically generate a list of reminders for any task or event"
    let requiresAPI = true
    var view: AnyView { AnyView(ReminderGeneratorView()) }
}
