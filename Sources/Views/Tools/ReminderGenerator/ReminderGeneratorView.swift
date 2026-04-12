import SwiftUI

struct ReminderGeneratorView: View {
    @StateObject private var backend = ReminderGeneratorBackend()
    @State private var input: String = ""

    var body: some View {
        ToolDetailView(tool: ReminderGeneratorTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Notes or Transcript") {
                    TextEditor(text: $input)
                        .frame(height: 150)
                        .padding(8)
                }

                Button(action: {
                    Task { await backend.generateReminders(from: input) }
                }) {
                    if backend.isProcessing {
                        ProgressView()
                    } else {
                        Text("Extract Reminders")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(input.isEmpty || backend.isProcessing)

                if !backend.reminders.isEmpty {
                    ToolInputSection("Generated Reminders") {
                        ForEach(backend.reminders, id: \.self) { reminder in
                            HStack {
                                Image(systemName: "circle")
                                Text(reminder)
                                Spacer()
                            }
                            .padding()
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

struct ReminderGeneratorTool: Tool {
    let name = "Reminder Generator"
    let icon = "bell.badge"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Extract actionable reminders and tasks from text using AI"
    let requiresAPI = true
    var view: AnyView { AnyView(ReminderGeneratorView()) }
}
