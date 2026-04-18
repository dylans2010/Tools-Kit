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
        VStack(spacing: 0) {
            compactHeader
                .padding(.horizontal, 12)
                .padding(.top, 10)

            CalendarModeSelector(selectedMode: $selectedView)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

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
        .sheet(isPresented: $showingAISheet) {
            aiPlanningSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var compactHeader: some View {
        WorkspaceSurfaceCard {
            VStack(spacing: 8) {
                CalendarHeaderView(selectedDate: $selectedDate, selectedView: $selectedView) {
                    showingCreate = true
                } onToday: {
                    selectedDate = Date()
                    selectedView = .today
                }

                HStack(spacing: 8) {
                    quickIconButton("calendar.badge.clock", label: "Focus Week") {
                        runAIPlanner(using: "Plan my week with focus blocks and break time.")
                    }
                    quickIconButton("arrow.triangle.branch", label: "Conflict Solver") {
                        runAIPlanner(using: "Find scheduling conflicts and suggest alternatives.")
                    }
                    quickIconButton("sparkles", label: "AI Tools") {
                        showingAISheet = true
                    }
                }
            }
        }
    }

    private var aiPlanningSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("AI Calendar Tools")
                    .font(.headline)
                Text("Use natural language like \"schedule study time this week\" and AI will infer details.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Ask naturally…", text: $aiPrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

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
                        Button("Add First Suggested Event") { addSuggestedEvent(first) }
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
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
            ForEach(items.prefix(2), id: \.self) { item in
                Text("• \(item)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private func runAIPlanner() {
        runAIPlanner(using: aiPrompt)
    }

    private func runAIPlanner(using input: String) {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    aiError = "Couldn’t build a schedule yet. Natural language is supported, so rough requests are okay."
                    aiLoading = false
                }
            }
        }
    }

    private func addSuggestedEvent(_ draft: CalendarManager.AICalendarEventDraft) {
        guard let start = isoFormatter.date(from: draft.startISO8601),
              let end = isoFormatter.date(from: draft.endISO8601) else {
            aiError = "Couldn’t parse event time this round. Please try again."
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
