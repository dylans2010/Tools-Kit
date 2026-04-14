import SwiftUI

struct CalendarHomeView: View {
    @StateObject private var manager = CalendarManager.shared
    @State private var selectedView: CalendarMode = .month
    @State private var selectedDate = Date()
    @State private var showingCreate = false
    @State private var selectedEvent: CalendarEvent? = nil

    var body: some View {
        VStack(spacing: 0) {
            CalendarHeaderView(selectedDate: $selectedDate, selectedView: $selectedView) {
                showingCreate = true
            } onToday: {
                withAnimation { selectedDate = Date(); selectedView = .today }
            }
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedView)
        }
        .ignoresSafeArea(edges: .bottom)
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
