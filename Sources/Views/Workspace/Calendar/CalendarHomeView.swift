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
            VStack(spacing: 0) {
                calendarMetricsHeader
                    .padding()

                CalendarModeSelector(selectedMode: $selectedView)
                    .padding(.horizontal)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(selectedDate.formatted(.dateTime.month().year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingAISheet = true } label: {
                        Image(systemName: "sparkles")
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { selectedDate = Date() } label: {
                        Text("Today").font(.subheadline.bold())
                    }

                    Button { showingCreate = true } label: {
                        Image(systemName: "plus")
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
            CalendarMetricLabel(title: "Today", value: "\(manager.events(on: Date()).count)", icon: "sun.max")
            CalendarMetricLabel(title: "Conflicts", value: String(format: "%.0f%%", manager.conflictProbability(for: selectedDate) * 100), icon: "exclamationmark.triangle")
            CalendarMetricLabel(title: "Upcoming", value: "\(manager.upcomingEvents().count)", icon: "clock")
        }
    }
}

private struct CalendarMetricLabel: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
                            .background(selectedMode == mode ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                            .foregroundStyle(selectedMode == mode ? .white : .secondary)
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
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                        Text("Predictive Scheduling")
                            .font(.headline)
                        Text("Describe your plans and I'll find the optimal time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }

                Section {
                    TextField("Describe your plans…", text: $prompt, axis: .vertical)
                        .lineLimit(5...10)
                }

                Section {
                    Button {
                        isProcessing = true
                    } label: {
                        Text("Optimize My Schedule")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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
