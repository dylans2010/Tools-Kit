import SwiftUI

struct ReminderGeneratorView: View {
    @State private var topic = ""
    @State private var reminders: [String] = []

    var body: some View {
        VStack {
            TextField("What are you planning? (e.g. Travel to Japan)", text: $topic)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button("Generate Reminders") {
                reminders = ["Check passport validity", "Book flights", "Reserve hotels", "Apply for visa"]
            }
            .buttonStyle(.borderedProminent)

            List(reminders, id: \.self) { reminder in
                Label(reminder, systemImage: "bell")
            }
        }
        .navigationTitle("Smart Reminders")
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
