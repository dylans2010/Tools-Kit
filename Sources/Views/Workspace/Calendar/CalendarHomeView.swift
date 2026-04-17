import SwiftUI

struct CalendarHomeView: View {
    @StateObject private var manager = CalendarManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedView: CalendarMode = .month
    @State private var selectedDate = Date()
    @State private var showingCreate = false
    @State private var selectedEvent: CalendarEvent? = nil

    @State private var aiDigest: String?
    @State private var isGeneratingDigest = false
    var body: some View {
        VStack(spacing: 0) {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.07, green: 0.10, blue: 0.12), Color(red: 0.05, green: 0.07, blue: 0.10)]
                    : [Color(red: 0.97, green: 1.0, blue: 0.98), Color(red: 0.93, green: 0.98, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                CalendarHeaderView(selectedDate: $selectedDate, selectedView: $selectedView) {
                    showingCreate = true
                } onToday: {
                    withAnimation { selectedDate = Date(); selectedView = .today }
                }

                aiPlannerCard
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                CalendarModeSelector(selectedMode: $selectedView)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                Divider()
            Group {
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
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedView)
                .onAppear(perform: generateAIDigest)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                CreateEventView(prefilledDate: selectedDate) { event in
                    manager.addEvent(event)
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                EventDetailView(event: event)
            }
        }
    }

    private var aiPlannerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AI Planner", systemImage: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)

                Spacer()

                Button {
                    generateAIDigest()
                } label: {
                    if isGeneratingDigest {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.plain)
            }

            if let aiDigest {
                Group {
                    if let parsed = try? AttributedString(markdown: aiDigest) {
                        Text(parsed)
                    } else {
                        Text(aiDigest)
                    }
                }
                .font(.caption)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Generate a short AI view of top priorities, timing risks, and next actions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.white.opacity(0.07) : Color.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.20), lineWidth: 1)
                )
        )
    }

    private func generateAIDigest() {
        let upcoming = manager.upcomingEvents(limit: 20)
        guard !upcoming.isEmpty else {
            aiDigest = "### Calendar Priority\nNo upcoming events found."
            return
        }

        isGeneratingDigest = true

        let context = upcoming.map { event in
            "Title: \(event.title) | Date: \(event.formattedDate) | Time: \(event.formattedTimeRange) | Priority: \(event.priority.rawValue) | Location: \(event.location) | Description: \(event.description)"
        }.joined(separator: "\n")

        let prompt = """
        Analyze all events and respond in concise markdown only.
        Keep the response under 120 words.
        Include exactly these sections:
        ### Priority Today
        ### Upcoming Risks
        ### Next Best Actions
        Focus on scheduling conflicts, urgent items, and what to do first.

        Events:
        \(context)
        """

        Task {
            do {
                let summary = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: "You are a calendar productivity assistant. Be concise and highly actionable."
                )
                await MainActor.run {
                    aiDigest = summary
                    isGeneratingDigest = false
                }
            } catch {
                await MainActor.run {
                    aiDigest = "Unable to generate planner insights right now."
                    isGeneratingDigest = false
                }
            }
        }
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(selectedMode == mode ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                        )
                        .foregroundColor(selectedMode == mode ? .accentColor : .primary)
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
                    .font(.title2.bold())
                Text(subtitleText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { shift(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                }

                Button(action: { shift(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                }

                Button(action: onToday) {
                    Text("Today")
                        .font(.caption.bold())
                }

                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var titleText: String {
        let formatter = DateFormatter()
        switch selectedView {
        case .year:
            formatter.dateFormat = "yyyy"
        case .month, .week, .today, .agenda:
            formatter.dateFormat = "LLLL yyyy"
        }
        return formatter.string(from: selectedDate)
    }

    private var subtitleText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
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
