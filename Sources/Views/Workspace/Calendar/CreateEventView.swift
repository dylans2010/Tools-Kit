import SwiftUI

struct CreateEventView: View {
    var prefilledDate: Date = Date()
    var existingEvent: CalendarEvent? = nil
    var onSave: (CalendarEvent) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600)
    @State private var location: String = ""
    @State private var priority: EventPriority = .normal

    private var isEditing: Bool { existingEvent != nil }

    var body: some View {
        Form {
            Section("Event Details") {
                TextField("Event title", text: $title)
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Description (optional)")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $description)
                        .frame(minHeight: 60)
                }
                TextField("Location (optional)", text: $location)
            }

            Section("Date & Time") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
            }

            Section("Priority") {
                Picker("Priority", selection: $priority) {
                    ForEach(EventPriority.allCases, id: \.self) { p in
                        HStack {
                            Circle()
                                .fill(Color(hex: p.color) ?? .blue)
                                .frame(width: 10, height: 10)
                            Text(p.rawValue)
                        }
                        .tag(p)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                Button(action: save) {
                    Text(isEditing ? "Save Changes" : "Create Event")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle(isEditing ? "Edit Event" : "New Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear {
            if let e = existingEvent {
                title = e.title
                description = e.description
                date = e.date
                startTime = e.startTime
                endTime = e.endTime
                location = e.location
                priority = e.priority
            } else {
                date = prefilledDate
                startTime = prefilledDate
                endTime = prefilledDate.addingTimeInterval(3600)
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var event = existingEvent ?? CalendarEvent(title: trimmed)
        event.title = trimmed
        event.description = description
        event.date = date
        event.startTime = startTime
        event.endTime = max(endTime, startTime.addingTimeInterval(60))
        event.location = location
        event.priority = priority
        onSave(event)
        dismiss()
    }
}
