import SwiftUI

struct CalendarMonthView: View {
    @StateObject private var manager = CalendarManager.shared
    @Binding var selectedDate: Date
    @Binding var selectedEvent: CalendarEvent?

    @Namespace private var animation
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let daySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(daySymbols, id: \.self) { symbol in
                    Text(symbol.prefix(1))
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(daysInGrid(), id: \.self) { date in
                    ModernMonthDayCell(
                        date: date,
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month),
                        isToday: calendar.isDateInToday(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        events: manager.events(on: date),
                        namespace: animation
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = date
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .background(Color(.systemBackground))
            .ignoresSafeArea(edges: .horizontal)

            Divider()

            List {
                let events = manager.events(on: selectedDate)
                if events.isEmpty {
                    Text("No events for this day")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                        .padding(.top, 20)
                } else {
                    ForEach(events) { event in
                        Button {
                            selectedEvent = event
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: event.priority.color) ?? .blue)
                                    .frame(width: 8, height: 8)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title)
                                        .font(.subheadline.bold())
                                    Text(event.formattedTimeRange)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .transition(.move(edge: .bottom))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

struct ModernMonthDayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let events: [CalendarEvent]
    var namespace: Namespace.ID
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 36, height: 36)
                            .matchedGeometryEffect(id: "selection", in: namespace)
                    } else if isToday {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(.body, design: .rounded).bold())
                        .foregroundColor(isSelected ? .white : (isToday ? .accentColor : (isCurrentMonth ? .primary : .secondary.opacity(0.3))))
                }
                .frame(height: 40)

                HStack(spacing: 3) {
                    ForEach(events.prefix(3)) { event in
                        Circle()
                            .fill(Color(hex: event.priority.color) ?? .blue)
                            .frame(width: 5, height: 5)
                    }

                    if events.count > 3 {
                        Text("+\(events.count - 3)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
