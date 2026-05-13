import SwiftUI

struct AISummarySheet: View {
    let title: String
    let location: String
    let date: Date
    let priority: EventPriority
    let description: String
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: String

    init(title: String, location: String, date: Date, priority: EventPriority, description: String, onApply: @escaping (String) -> Void) {
        self.title = title
        self.location = location
        self.date = date
        self.priority = priority
        self.description = description
        self.onApply = onApply

        let formattedDate = date.formatted(date: .abbreviated, time: .shortened)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle = trimmedTitle.isEmpty ? "Untitled Event" : trimmedTitle
        let normalizedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        var seeded = "Agenda for \(normalizedTitle) on \(formattedDate)."
        if !normalizedLocation.isEmpty {
            seeded += " Location: \(normalizedLocation)."
        }
        seeded += " Priority: \(priority.rawValue)."
        if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            seeded += "\\n\\n\(description)"
        }

        _draft = State(initialValue: seeded)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $draft)
                        .frame(minHeight: 220)
                } header: {
                    Text("AI Draft")
                }
            }
            .navigationTitle("AI Agenda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(draft)
                        dismiss()
                    }
                }
            }
        }
    }
}
