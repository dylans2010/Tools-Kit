import SwiftUI

struct CalendarHomeView: View {
    @StateObject private var manager = CalendarManager.shared
    @State private var selectedView: CalendarMode = .month
    @State private var selectedDate = Date()
    @State private var showingCreate = false
    @State private var selectedEvent: CalendarEvent?
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var aiInsights: CalendarManager.AICalendarInsights?

    var body: some View {
        VStack(spacing: 0) {
            CalendarHeaderView(selectedDate: $selectedDate, selectedView: $selectedView) {
                showingCreate = true
            } onToday: {
                selectedDate = Date()
                selectedView = .today
            }
            .background(.ultraThinMaterial)

            aiPlannerCard
                .padding(12)

            CalendarModeSelector(selectedMode: $selectedView)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            Divider()

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
        .navigationTitle("Calendar")
        .sheet(item: $selectedEvent) { event in
            NavigationStack { EventDetailView(event: event) }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                CreateEventView(prefilledDate: selectedDate) { manager.addEvent($0) }
            }
        }
    }

    private var aiPlannerCard: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("AI Scheduler")
                    .font(.headline)
                TextField("Convert text into events or optimize your week…", text: $aiPrompt)
                    .textFieldStyle(.roundedBorder)
                Button("Run Scheduler", action: runAIPlanner)
                    .buttonStyle(.borderedProminent)
                    .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)

                if aiLoading {
                    WorkspaceSkeletonLine()
                    WorkspaceSkeletonLine(widthRatio: 0.7)
                } else if let aiError {
                    Text(aiError)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let aiInsights {
                    insightList("Conflicts", aiInsights.conflicts)
                    insightList("Optimal Scheduling", aiInsights.optimalScheduling)
                    if let first = aiInsights.parsedEvents.first {
                        Button("Add First Suggested Event") { addSuggestedEvent(first) }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private func insightList(_ title: String, _ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func runAIPlanner() {
        let prompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                let insights = try await manager.generateSchedulingInsights(from: prompt)
                await MainActor.run {
                    aiInsights = insights
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Scheduling response failed validation. Please retry."
                    aiLoading = false
                }
            }
        }
    }

    private func addSuggestedEvent(_ draft: CalendarManager.AICalendarEventDraft) {
        let formatter = ISO8601DateFormatter()
        guard let start = formatter.date(from: draft.startISO8601),
              let end = formatter.date(from: draft.endISO8601) else {
            aiError = "Suggested event had invalid dates."
            return
        }
        let event = CalendarEvent(
            title: draft.title,
            description: draft.details,
            date: start,
            startTime: start,
            endTime: end,
            location: draft.location
        )
        manager.addEvent(event)
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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.title3.weight(.semibold))
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: { shift(by: -1) }) { Image(systemName: "chevron.left") }
            Button(action: { shift(by: 1) }) { Image(systemName: "chevron.right") }
            Button("Today", action: onToday)
                .buttonStyle(.bordered)
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var titleText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = selectedView == .year ? "yyyy" : "LLLL yyyy"
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
