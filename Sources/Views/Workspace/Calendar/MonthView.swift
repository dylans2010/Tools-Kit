import SwiftUI

struct MonthView: View {
    @ObservedObject var manager: CalendarManager
    @Binding var selectedDate: Date
    @Binding var selectedEvent: CalendarEvent?

    @State private var displayMonth: Date = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let dayHeaders = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthNavigation
                dayHeaderRow
                daysGrid
                selectedDayEvents
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var monthNavigation: some View {
        HStack {
            Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(monthTitle).font(.headline)
            Spacer()
            Button { changeMonth(by: 1) } label: { Image(systemName: "chevron.right") }
        }
    }

    private var monthTitle: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: displayMonth)
    }

    private var dayHeaderRow: some View {
        HStack {
            ForEach(dayHeaders, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(monthCells(), id: \.self) { date in
                if let date {
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        eventCount: manager.events(on: date).count
                    )
                    .onTapGesture { selectedDate = date }
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    private var selectedDayEvents: some View {
        VStack(alignment: .leading, spacing: 8) {
            let events = manager.events(on: selectedDate)
            if !events.isEmpty {
                Text(selectedDate, style: .date).font(.headline)
                ForEach(events) { event in
                    Button { selectedEvent = event } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: event.priority.colorHex) ?? .accentColor)
                                .frame(width: 8, height: 8)
                            Text(event.title).font(.subheadline).lineLimit(1)
                            Spacer()
                            Text(event.formattedTimeRange).font(.caption).foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func monthCells() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        var cells: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            cells.append(calendar.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayMonth) {
            displayMonth = newMonth
        }
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let eventCount: Int

    private var label: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(isToday ? Color.accentColor : (isSelected ? Color.accentColor.opacity(0.3) : Color.clear))
                    .frame(width: 34, height: 34)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(isToday ? .white : .primary)
            }
            if eventCount > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<min(eventCount, 3), id: \.self) { _ in
                        Circle().fill(Color.accentColor).frame(width: 4, height: 4)
                    }
                }
            } else {
                Color.clear.frame(height: 4)
            }
        }
        .frame(height: 46)
    }
}
