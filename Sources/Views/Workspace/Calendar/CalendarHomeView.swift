import SwiftUI

struct CalendarHomeView: View {
    @StateObject private var manager = CalendarManager.shared
    @State private var selectedView: CalendarMode = .month
    @State private var selectedDate = Date()
    @State private var showingCreate = false
    @State private var selectedEvent: CalendarEvent?
    @State private var showingAISheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    calendarMetricsHeader
                        .padding()

                    CalendarModeSelector(selectedMode: $selectedView)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    Divider().opacity(0.1)

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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(selectedDate.formatted(.dateTime.month().year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingAISheet = true } label: {
                        Image(systemName: "sparkles")
                            .foregroundStyle(LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .top, endPoint: .bottom))
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { selectedDate = Date() } label: {
                        Text("Today").font(.subheadline.bold())
                    }

                    Button { showingCreate = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
            .sheet(isPresented: $showingCreate) {
                CreateEventView(prefilledDate: selectedDate) { manager.addEvent($0) }
            }
            .sheet(isPresented: $showingAISheet) {
                CalendarAIPlannerView()
            }
        }
    }

    private var calendarMetricsHeader: some View {
        HStack(spacing: 12) {
            metricCard(title: "Today", value: "\(manager.events(on: Date()).count)", icon: "sun.max.fill", color: .orange)
            metricCard(title: "Conflicts", value: String(format: "%.0f%%", manager.conflictProbability(for: selectedDate) * 100), icon: "exclamationmark.triangle.fill", color: .red)
            metricCard(title: "Upcoming", value: "\(manager.upcomingEvents().count)", icon: "clock.fill", color: .blue)
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.caption.bold()).foregroundStyle(.secondary)
            }
            Text(value).font(.title3.bold()).foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

enum CalendarMode: String, CaseIterable, Identifiable {
    case today = "Today", agenda = "Agenda", week = "Week", month = "Month", year = "Year"
    var id: String { rawValue }
}

struct CalendarModeSelector: View {
    @Binding var selectedMode: CalendarMode

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CalendarMode.allCases) { mode in
                    Button {
                        withAnimation { selectedMode = mode }
                    } label: {
                        Text(mode.rawValue)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedMode == mode ? Color.blue : Color.white.opacity(0.1), in: Capsule())
                            .foregroundStyle(selectedMode == mode ? Color.white : Color.secondary)
                    }
                }
            }
        }
    }
}

struct CalendarAIPlannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(.purple)
                        Text("Predictive Scheduling")
                            .font(.headline)
                        Text("Describe your plans and I'll find the optimal time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    TextEditor(text: $prompt)
                        .frame(height: 150)
                        .padding(8)
                        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))

                    Button {
                        // AI Logic call
                    } label: {
                        Text("Optimize My Schedule")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue, in: Capsule())
                            .foregroundStyle(.white)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
