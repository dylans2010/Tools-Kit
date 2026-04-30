import SwiftUI

struct CalendarMonthView: View {
    @StateObject private var manager = CalendarManager.shared
    @Binding var selectedDate: Date
    @Binding var selectedEvent: CalendarEvent?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let daySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(daySymbols, id: \.self) { symbol in
                    Text(symbol.prefix(1))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(daysInGrid(), id: \.self) { date in
                    MonthDayCell(
                        date: date,
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month),
                        isToday: calendar.isDateInToday(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        hasEvents: manager.hasEvents(on: date)
                    ) {
                        selectedDate = date
                    }
                }
            }

            dayEventsList
        }
    }

    private var dayEventsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                let events = manager.events(on: selectedDate)
                if events.isEmpty {
                    Text("No events for this day").font(.caption).foregroundStyle(.secondary).padding(.top, 40)
                } else {
                    ForEach(events) { event in
                        EventAgendaRow(event: event)
                            .onTapGesture { selectedEvent = event }
                    }
                }
            }
            .padding()
        }
        .background(Color.white.opacity(0.02))
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
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(isSelected ? .white : (isToday ? .blue : (isCurrentMonth ? .white : .secondary.opacity(0.3))))
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.blue : Color.clear, in: Circle())

                if hasEvents {
                    Circle().fill(.blue).frame(width: 4, height: 4)
                } else {
                    Spacer().frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
