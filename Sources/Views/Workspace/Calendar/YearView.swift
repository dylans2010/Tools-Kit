import SwiftUI

struct YearView: View {
    @ObservedObject var manager: CalendarManager
    @Binding var selectedDate: Date
    var onMonthTap: () -> Void

    @State private var displayYear: Int = Calendar.current.component(.year, from: Date())

    private let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                yearNavigation
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<12, id: \.self) { monthIndex in
                        MonthMiniView(
                            year: displayYear,
                            monthIndex: monthIndex,
                            monthName: monthNames[monthIndex],
                            eventCount: eventCount(year: displayYear, month: monthIndex + 1),
                            isCurrentMonth: isCurrentMonth(monthIndex)
                        )
                        .onTapGesture {
                            if let date = monthDate(year: displayYear, month: monthIndex + 1) {
                                selectedDate = date
                                onMonthTap()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
    }

    private var yearNavigation: some View {
        HStack {
            Button { displayYear -= 1 } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text("\(displayYear)").font(.headline)
            Spacer()
            Button { displayYear += 1 } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal)
    }

    private func eventCount(year: Int, month: Int) -> Int {
        events.filter { event in
            let c = calendar.dateComponents([.year, .month], from: event.date)
            return c.year == year && c.month == month
        }.count
    }

    private var events: [CalendarEvent] { manager.events }

    private func isCurrentMonth(_ monthIndex: Int) -> Bool {
        let now = Date()
        return calendar.component(.year, from: now) == displayYear &&
               calendar.component(.month, from: now) == monthIndex + 1
    }

    private func monthDate(year: Int, month: Int) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))
    }
}

private struct MonthMiniView: View {
    let year: Int
    let monthIndex: Int
    let monthName: String
    let eventCount: Int
    let isCurrentMonth: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(monthName)
                .font(.subheadline.bold())
                .foregroundColor(isCurrentMonth ? .accentColor : .primary)
            if eventCount > 0 {
                Text("\(eventCount)")
                    .font(.caption2.bold())
                    .padding(6)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .clipShape(Circle())
            } else {
                Color.clear.frame(height: 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(isCurrentMonth ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentMonth ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }
}
