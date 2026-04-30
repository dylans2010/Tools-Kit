import SwiftUI

struct CalendarHomeView: View {
    @StateObject private var manager = CalendarManager.shared
    @State private var selectedView: CalendarMode = .month
    @State private var selectedDate = Date()
    @State private var showingCreate = false
    @State private var selectedEvent: CalendarEvent?
    @State private var showingAISheet = false
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var aiInsights: CalendarManager.AICalendarInsights?
    private let isoFormatter = ISO8601DateFormatter()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                    Color(red: 0.09, green: 0.11, blue: 0.18),
                    Color(red: 0.14, green: 0.08, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                dashboardHeader
                    .padding(.horizontal, 12)
                    .padding(.top, 10)

                CalendarModeSelector(selectedMode: $selectedView)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                Divider().opacity(0.3)

                Group {
                    switch selectedView {
                    case .month:
                        CalendarMonthView(selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                    case .week:
                        CalendarWeekView(selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                    case .year:
                        CalendarYearView(selectedDate: $selectedDate, selectedView: $selectedView)
                    case .agenda:
                        CalendarAgendaView(selectedEvent: $selectedEvent)
                    case .today:
                        CalendarTodayView(selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Calendar")
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                EventDetailView(event: event)
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                CreateEventView(prefilledDate: selectedDate) { manager.addEvent($0) }
            }
        }
        .sheet(isPresented: $showingAISheet) {
            aiPlanningSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var dashboardHeader: some View {
        WorkspaceSurfaceCard {
            VStack(spacing: 14) {
                CalendarHeaderView(selectedDate: $selectedDate, selectedView: $selectedView) {
                    showingCreate = true
                } onToday: {
                    selectedDate = Date()
                    selectedView = .today
                }

                HStack(spacing: 10) {
                    calendarMetric(title: "Today", value: "\(manager.events(on: Date()).count)", icon: "sun.max.fill", tint: .orange)
                    calendarMetric(title: "Upcoming", value: "\(manager.upcomingEvents(limit: 99).count)", icon: "clock.fill", tint: .blue)
                    calendarMetric(title: "Total", value: "\(manager.events.count)", icon: "calendar.badge.plus", tint: .indigo)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        quickIconButton("calendar.badge.clock", label: "Focus Week") {
                            runAIPlanner(using: "Plan my week with focus blocks and break time.")
                        }
                        quickIconButton("arrow.triangle.branch", label: "Conflict Solver") {
                            runAIPlanner(using: "Find scheduling conflicts and suggest alternatives.")
                        }
                        quickIconButton("plus.circle.fill", label: "New Event") {
                            showingCreate = true
                        }
                        quickIconButton("calendar.day.timeline.left", label: "Today") {
                            selectedDate = Date()
                            selectedView = .today
                        }
                        quickIconButton("sparkles", label: "AI Tools") {
                            showingAISheet = true
                        }
                        quickIconButton("calendar.circle", label: "Month") {
                            selectedView = .month
                        }
                        quickIconButton("calendar", label: "Agenda") {
                            selectedView = .agenda
                        }
                    }
                }
            }
        }
    }

    private func calendarMetric(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var aiPlanningSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Calendar Tools")
                    .font(.headline)
                Text("Use natural language like \"schedule study time this week\" and AI will infer details.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Ask naturally…", text: $aiPrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        quickIconButton("calendar.badge.clock", label: "Focus Week") {
                            runAIPlanner(using: "Plan my week with focus blocks and break time.")
                        }
                        quickIconButton("arrow.triangle.branch", label: "Conflict Solver") {
                            runAIPlanner(using: "Find scheduling conflicts and suggest alternatives.")
                        }
                        quickIconButton("list.bullet.rectangle", label: "Agenda Cleanup") {
                            runAIPlanner(using: "Turn this schedule into a prioritized agenda.")
                        }
                        quickIconButton("repeat", label: "Recurring") {
                            runAIPlanner(using: "Suggest recurring meeting patterns and cadence.")
                        }
                    }
                }

                Button("Generate Plan", action: runAIPlanner)
                    .buttonStyle(.borderedProminent)
                    .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)

                if aiLoading {
                    WorkspaceSkeletonLine()
                } else if let aiError {
                    Text(aiError)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let aiInsights {
                    if let first = aiInsights.parsedEvents.first {
                        Button("Add First Suggested Event") {
                            addSuggestedEvent(first)
                        }
                        .buttonStyle(.bordered)
                    }
                    compactInsightRow(title: "Conflicts", items: aiInsights.conflicts)
                    compactInsightRow(title: "Optimized", items: aiInsights.optimalScheduling)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("AI Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingAISheet = false }
                }
            }
        }
    }

    private func compactInsightRow(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            if items.isEmpty {
                Text("No insights yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items.prefix(3), id: \.self) { item in
                    Text("• \(item)")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func runAIPlanner() {
        runAIPlanner(using: aiPrompt)
    }

    private func runAIPlanner(using prompt: String) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            aiError = "Please enter a prompt first."
            return
        }

        aiPrompt = trimmedPrompt
        aiLoading = true
        aiError = nil

        Task {
            do {
                let insights = try await manager.generateSchedulingInsights(from: trimmedPrompt)
                await MainActor.run {
                    aiInsights = insights
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = error.localizedDescription
                    aiLoading = false
                }
            }
        }
    }

    private func addSuggestedEvent(_ draft: CalendarManager.AICalendarEventDraft) {
        guard
            let start = isoFormatter.date(from: draft.startISO8601),
            let end = isoFormatter.date(from: draft.endISO8601)
        else {
            aiError = "Could not parse suggested event time."
            return
        }

        let newEvent = CalendarEvent(
            title: draft.title,
            description: draft.details,
            date: start,
            startTime: start,
            endTime: end,
            location: draft.location,
            priority: .normal
        )

        manager.addEvent(newEvent)
        selectedDate = start
        selectedView = .today
        aiError = nil
    }

    private func quickIconButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(label)
    }
}

enum CalendarMode: String, CaseIterable {
    case month = "Month"
    case week = "Week"
    case year = "Year"
    case agenda = "Agenda"
    case today = "Today"
}

private struct CalendarModeSelector: View {
    @Binding var selectedMode: CalendarMode

    var body: some View {
        HStack(spacing: 8) {
            ForEach(CalendarMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedMode = mode }
                } label: {
                    Text(mode.rawValue)
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(selectedMode == mode ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CalendarHeaderView: View {
    @Binding var selectedDate: Date
    @Binding var selectedView: CalendarMode
    var onAdd: () -> Void
    var onToday: () -> Void
    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(titleText)
                    .font(.headline)
                Text(subtitleText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: { shift(by: -1) }) { Image(systemName: "chevron.left") }
            Button(action: { shift(by: 1) }) { Image(systemName: "chevron.right") }
            Button("Today", action: onToday)
                .buttonStyle(.bordered)
                .controlSize(.small)
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var titleText: String {
        let formatter = DateFormatter()
        switch selectedView {
        case .year:
            formatter.dateFormat = "yyyy"
        case .month, .week, .agenda, .today:
            formatter.dateFormat = "LLLL yyyy"
        }
        return formatter.string(from: selectedDate)
    }

    private var subtitleText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }

    private func shift(by amount: Int) {
        switch selectedView {
        case .year:
            selectedDate = calendar.date(byAdding: .year, value: amount, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: amount, to: selectedDate) ?? selectedDate
        case .week, .agenda, .today:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: amount, to: selectedDate) ?? selectedDate
        }
    }
}
