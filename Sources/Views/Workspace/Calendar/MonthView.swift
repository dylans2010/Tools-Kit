import SwiftUI

struct CalendarMonthView: View {
    @StateObject private var manager = CalendarManager.shared
    @Binding var selectedDate: Date
    @Binding var selectedView: CalendarHomeView.CalendarViewType
    @Binding var selectedEvent: CalendarEvent?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let daySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        VStack(spacing: 0) {
            monthHeader

            // Day labels
            HStack(spacing: 0) {
                ForEach(daySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))

            Divider()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(daysInGrid(), id: \.self) { date in
                        MonthDayCell(date: date,
                                     isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month),
                                     isToday: calendar.isDateInToday(date),
                                     isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                     hasEvents: manager.hasEvents(on: date))
                        {
                            selectedDate = date
                        }
                    }
                }
                .padding(.horizontal, 4)

                if !manager.events(on: selectedDate).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(shortDate(selectedDate))
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(manager.events(on: selectedDate)) { event in
                            Button { selectedEvent = event } label: {
                                EventAgendaRow(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthYearLabel)
                .font(.headline)
            Spacer()
            Button {
                selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var monthYearLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedDate)
    }

    private func daysInGrid() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let firstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start) else { return [] }

        var days: [Date] = []
        var current = firstWeek.start
        while current < monthInterval.end || days.count % 7 != 0 {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
            if days.count > 42 { break }
        }
        return days
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        return f.string(from: date)
    }
}

struct MonthDayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isToday ? Color.accentColor : (isSelected ? Color.accentColor.opacity(0.15) : Color.clear))
                        .frame(width: 32, height: 32)
                    Text(dayNumber)
                        .font(.system(.subheadline, design: .rounded).weight((isToday || isSelected) ? .bold : .regular))
                        .foregroundColor(isToday ? .white : (isCurrentMonth ? .primary : .secondary.opacity(0.5)))
                }

                Circle()
                    .fill(hasEvents ? Color.accentColor : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
}
