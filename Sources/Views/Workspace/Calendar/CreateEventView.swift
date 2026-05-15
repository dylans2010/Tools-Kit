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
    @State private var showingAISummarySheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                Form {
                    Section {
                        TextField("Event Title", text: $title)
                            .font(.headline)

                        TextField("Location", text: $location)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))

                    Section {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                        DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))

                    Section {
                        Button { showingAISummarySheet = true } label: {
                            Label("Generate AI Agenda", systemImage: "sparkles")
                                .foregroundStyle(.secondary)
                        }

                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Description / Agenda").foregroundStyle(.secondary).padding(.top, 8)
                            }
                            TextEditor(text: $description)
                                .frame(minHeight: 120)
                        }
                    } header: {
                        Text("Intelligence")
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))

                    Section {
                        Picker("Priority", selection: $priority) {
                            ForEach(EventPriority.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existingEvent == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let e = existingEvent {
                    title = e.title; description = e.description; date = e.date; startTime = e.startTime; endTime = e.endTime; location = e.location; priority = e.priority
                } else {
                    date = prefilledDate; startTime = prefilledDate; endTime = prefilledDate.addingTimeInterval(3600)
                }
            }
            .sheet(isPresented: $showingAISummarySheet) {
                AISummarySheet(title: title, location: location, date: date, priority: priority, description: description) { description = $0 }
            }
        }
    }

    private func save() {
        var event = existingEvent ?? CalendarEvent(title: title)
        event.title = title; event.description = description; event.date = date; event.startTime = startTime; event.endTime = endTime; event.location = location; event.priority = priority
        onSave(event)
        dismiss()
    }
}
