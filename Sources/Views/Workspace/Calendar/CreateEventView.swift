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
                            Text("Description (Optional)")
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
    @Environment(\.colorScheme) private var colorScheme
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
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.10, green: 0.10, blue: 0.14), Color(red: 0.08, green: 0.08, blue: 0.12)]
                    : [Color(red: 0.99, green: 0.98, blue: 1.0), Color(red: 0.95, green: 0.93, blue: 0.99)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.indigo)
                    Text("Event Assistant")
                        .font(.headline)
                    Spacer()
                }
                .padding(.top)

                if isLoading {
                    Spacer()
                    ProgressView("Analyzing Event...")
                    Spacer()
                } else {
                    ScrollView {
                        Group {
                            if let parsed = try? AttributedString(markdown: aiSummary) {
                                Text(parsed)
                            } else {
                                Text(aiSummary)
                            }
                        }
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
        }
        .onAppear(perform: runAI)
    }

    private func runAI() {
        isLoading = true
        let prompt = """
        Analyze this calendar event and provide concise markdown only.
        Keep it short and practical.
        Use exactly these sections:
        ### Suggested Description
        ### Missing Details
        ### Preparation Checklist
        ### Completeness Score
        Use bullets where possible.

        Event Title: \(title)
        Location: \(location)
        Date & Time: \(date.description)
        Priority: \(priority.rawValue)
        Current Description: \(description)
        """

        Task {
            do {
                let result = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: "You are a concise planning assistant. Return short markdown only."
                )
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
