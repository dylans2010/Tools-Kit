import SwiftUI

struct CalendarYearView: View {
    @StateObject private var manager = CalendarManager.shared
    @Binding var selectedDate: Date
    @Binding var selectedView: CalendarMode

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    private var year: Int {
        calendar.component(.year, from: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            yearHeader

            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(1...12, id: \.self) { month in
                        if let monthDate = date(year: year, month: month) {
                            MiniMonthView(date: monthDate, selectedDate: $selectedDate, manager: manager) {
                                selectedDate = monthDate
                                selectedView = .month
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var yearHeader: some View {
        HStack {
            Button {
                selectedDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text("\(year)")
                .font(.headline)
            Spacer()
            Button {
                selectedDate = calendar.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func date(year: Int, month: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return calendar.date(from: components)
    }
}

struct MiniMonthView: View {
    let date: Date
    @Binding var selectedDate: Date
    @ObservedObject var manager: CalendarManager
    let onTap: () -> Void

    private let calendar = Calendar.current
    private let miniColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 4) {
            Button(action: onTap) {
                Text(monthName)
                    .font(.caption.bold())
                    .foregroundColor(isCurrentMonth ? .accentColor : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            LazyVGrid(columns: miniColumns, spacing: 2) {
                ForEach(daysInGrid(), id: \.self) { day in
                    if let day = day {
                        let isToday = calendar.isDateInToday(day)
                        let hasEvent = manager.hasEvents(on: day)
                        ZStack {
                            Circle()
                                .fill(isToday ? Color.accentColor : Color.clear)
                                .frame(width: 18, height: 18)
                            Text(dayNum(day))
                                .font(.system(size: 8, weight: isToday ? .bold : .regular))
                                .foregroundColor(isToday ? .white : (hasEvent ? .accentColor : .secondary))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(height: 18)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private var monthName: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date)
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    private func daysInGrid() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start) else { return [] }

        var days: [Date?] = []
        let offset = calendar.dateComponents([.day], from: firstWeek.start, to: monthInterval.start).day ?? 0
        for _ in 0..<offset { days.append(nil) }

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return days
    }

    private func dayNum(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
}
