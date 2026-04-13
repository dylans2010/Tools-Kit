import SwiftUI

struct CalendarHomeView: View {
    @StateObject private var manager = CalendarManager.shared
    @State private var calendarView: CalView = .month
    @State private var selectedDate = Date()
    @State private var showingCreate = false
    @State private var showingAI = false
    @State private var selectedEvent: CalendarEvent?
    @State private var showingEventDetail = false

    enum CalView: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case agenda = "Agenda"

        var icon: String {
            switch self {
            case .today: return "sun.max"
            case .week: return "calendar.badge.clock"
            case .month: return "calendar"
            case .year: return "calendar.badge.plus"
            case .agenda: return "list.bullet"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            viewPicker
            Divider()
            Group {
                switch calendarView {
                case .today: CalendarTodayView(manager: manager, selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                case .week: WeekView(manager: manager, selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                case .month: MonthView(manager: manager, selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                case .year: YearView(manager: manager, selectedDate: $selectedDate, onMonthTap: { calendarView = .month })
                case .agenda: AgendaView(manager: manager, selectedEvent: $selectedEvent)
                }
            }
        }
        .navigationTitle("Calendar")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { showingAI = true } label: { Image(systemName: "sparkles") }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateEventView(manager: manager, initialDate: selectedDate)
        }
        .sheet(isPresented: $showingAI) {
            AIEventPlannerView(manager: manager)
        }
        .navigationDestination(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                EventDetailView(event: event, manager: manager)
            }
        }
        .onChange(of: selectedEvent) { newValue in
            if newValue != nil { showingEventDetail = true }
        }
        .onChange(of: showingEventDetail) { showing in
            if !showing { selectedEvent = nil }
        }
    }

    private var viewPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(CalView.allCases, id: \.self) { view in
                    Button {
                        calendarView = view
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: view.icon).font(.caption)
                            Text(view.rawValue).font(.subheadline.bold())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(calendarView == view ? Color.accentColor : Color(.systemGray6))
                        .foregroundColor(calendarView == view ? .white : .primary)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - AI Event Planner

struct AIEventPlannerView: View {
    @ObservedObject var manager: CalendarManager
    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""
    @State private var aiOutput = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Describe your day or event…", text: $prompt, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                if isLoading {
                    ProgressView("Planning…").padding()
                } else if !aiOutput.isEmpty {
                    ScrollView {
                        Text(aiOutput)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 10) {
                        quickAction("Plan My Day", icon: "sun.max") { planDay() }
                        quickAction("Suggest Event Structure", icon: "rectangle.3.group") { suggestStructure() }
                        quickAction("Detect Conflicts", icon: "exclamationmark.triangle") { detectConflicts() }
                        quickAction("Generate Agenda", icon: "list.bullet") { generateAgenda() }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                if !prompt.isEmpty {
                    Button {
                        runCustomPrompt()
                    } label: {
                        Label("Plan with AI", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .disabled(isLoading)
                }
            }
            .padding(.top, 8)
            .navigationTitle("AI Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !aiOutput.isEmpty { Button("Clear") { aiOutput = ""; prompt = "" } }
                }
            }
        }
    }

    private func quickAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private func planDay() {
        let events = manager.events(on: Date()).map { "\($0.title) at \($0.formattedTimeRange)" }.joined(separator: "\n")
        let msg = events.isEmpty ? "I have no events scheduled today." : "Today's events:\n\(events)"
        run(prompt: "\(msg)\n\nPlan my day with optimal time blocks, breaks, and priorities. Include time estimates for each activity.")
    }

    private func suggestStructure() {
        let p = prompt.isEmpty ? "a productive workday" : prompt
        run(prompt: "Suggest an optimal event structure for: \(p). Include start time, end time, title, and description for each event.")
    }

    private func detectConflicts() {
        let events = manager.upcomingEvents.prefix(20).map { "\($0.title): \($0.formattedTimeRange) on \(DateFormatter.localizedString(from: $0.date, dateStyle: .short, timeStyle: .none))" }.joined(separator: "\n")
        run(prompt: "Check these calendar events for conflicts or scheduling issues:\n\(events.isEmpty ? "No events scheduled." : events)")
    }

    private func generateAgenda() {
        let events = manager.upcomingEvents.prefix(10).map { "- \($0.title) on \(DateFormatter.localizedString(from: $0.date, dateStyle: .medium, timeStyle: .none)) (\($0.formattedTimeRange))" }.joined(separator: "\n")
        run(prompt: "Generate a professional agenda from these events:\n\(events.isEmpty ? "No upcoming events." : events)")
    }

    private func runCustomPrompt() {
        run(prompt: prompt)
    }

    private func run(prompt: String) {
        isLoading = true
        Task {
            do {
                let result = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: "You are a calendar and scheduling assistant. Be specific, practical, and concise."
                )
                await MainActor.run { aiOutput = result; isLoading = false }
            } catch {
                await MainActor.run { aiOutput = "Could not get AI suggestions. Check your AI settings."; isLoading = false }
            }
        }
    }
}
