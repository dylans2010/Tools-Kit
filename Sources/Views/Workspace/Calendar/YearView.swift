import SwiftUI

struct CalendarYearView: View {
    @StateObject private var manager = CalendarManager.shared
    @Binding var selectedDate: Date
    @Binding var selectedView: CalendarMode

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(1...12, id: \.self) { month in
                    if let monthDate = dateFor(month: month) {
                        YearMiniMonthView(date: monthDate) {
                            selectedDate = monthDate
                            selectedView = .month
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func dateFor(month: Int) -> Date? {
        var components = calendar.dateComponents([.year], from: selectedDate)
        components.month = month
        components.day = 1
        return calendar.date(from: components)
    }
}

struct YearMiniMonthView: View {
    let date: Date
    let onTap: () -> Void
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date.formatted(.dateTime.month(.abbreviated)))
                .font(.caption.bold())
                .foregroundStyle(.blue)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { day in
                    if let day = day {
                        Text("\(calendar.component(.day, from: day))")
                            .font(.system(size: 6))
                            .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(height: 8)
                    }
                }
            }
        }
        .padding(10)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: onTap)
    }

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let startWeekday = calendar.component(.weekday, from: monthInterval.start)
        var days: [Date?] = Array(repeating: nil, count: startWeekday - 1)

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return days
    }
}
