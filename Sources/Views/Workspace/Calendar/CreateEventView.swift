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

    @State private var showAISummarySheet = false

    private var isEditing: Bool { existingEvent != nil }

    var body: some View {
        Form {
            Section("Event Details") {
                TextField("Event title", text: $title)

                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description (optional)")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }

                    Button {
                        showAISummarySheet = true
                    } label: {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                            .padding(8)
                            .background(Circle().fill(.purple.opacity(0.1)))
                    }
                    .padding(8)
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
        .sheet(isPresented: $showAISummarySheet) {
            AISummarySheet(title: title, location: location, date: date, priority: priority, description: description) { summary in
                self.description = summary
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
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

struct AISummarySheet: View {
    let title: String
    let location: String
    let date: Date
    let priority: EventPriority
    let description: String
    let onUseAsDescription: (String) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var aiSummary = ""
    @State private var isLoading = false
    @State private var copied = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Event Assistant")
                    .font(.headline)
                Spacer()
            }
            .padding(.top)

            if isLoading {
                Spacer()
                ProgressView("Analyzing event...")
                Spacer()
            } else {
                ScrollView {
                    Text(aiSummary)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Material.regular))
                }

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = aiSummary
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        Label(copied ? "Copied!" : "Copy Summary", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        onUseAsDescription(aiSummary)
                        dismiss()
                    } label: {
                        Text("Use as Description")
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
        }
        .padding(.horizontal)
        .onAppear(perform: runAI)
    }

    private func runAI() {
        isLoading = true
        let prompt = """
        Analyze this calendar event and provide:
        1. A suggested improved description (2-3 sentences)
        2. Any missing important details
        3. Preparation suggestions based on the location and priority
        4. A completeness score out of 10

        Event Title: \(title)
        Location: \(location)
        Date & Time: \(date.description)
        Priority: \(priority.rawValue)
        Current Description: \(description)
        """

        Task {
            do {
                let result = try await AIService.shared.processText(prompt: prompt)
                await MainActor.run {
                    aiSummary = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    aiSummary = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
