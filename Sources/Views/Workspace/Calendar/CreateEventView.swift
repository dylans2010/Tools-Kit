import SwiftUI

struct CreateEventView: View {
    @ObservedObject var manager: CalendarManager
    @Environment(\.dismiss) private var dismiss

    var editingEvent: CalendarEvent?
    var initialDate: Date

    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var location = ""
    @State private var priority: CalendarEvent.EventPriority = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. Team Meeting", text: $title)
                }

                Section("Details") {
                    TextEditor(text: $description)
                        .frame(minHeight: 60)
                    TextField("Location", text: $location)
                }

                Section("Date & Time") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(CalendarEvent.EventPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(editingEvent == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editingEvent == nil ? "Save" : "Update") { save() }
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let e = editingEvent {
                    title = e.title
                    description = e.description
                    date = e.date
                    startTime = e.startTime
                    endTime = e.endTime
                    location = e.location
                    priority = e.priority
                } else {
                    date = initialDate
                    startTime = initialDate
                    endTime = initialDate.addingTimeInterval(3600)
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let end = endTime > startTime ? endTime : startTime.addingTimeInterval(3600)
        if var existing = editingEvent {
            existing.title = trimmed
            existing.description = description
            existing.date = date
            existing.startTime = startTime
            existing.endTime = end
            existing.location = location
            existing.priority = priority
            manager.updateEvent(existing)
        } else {
            let event = CalendarEvent(
                title: trimmed,
                description: description,
                date: date,
                startTime: startTime,
                endTime: end,
                location: location,
                priority: priority
            )
            manager.addEvent(event)
        }
        dismiss()
    }
}
