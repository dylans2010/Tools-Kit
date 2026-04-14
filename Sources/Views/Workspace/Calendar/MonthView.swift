import SwiftUI

struct CalendarMonthView: View {
    @StateObject private var manager = CalendarManager.shared
    @Binding var selectedDate: Date
    @Binding var selectedView: CalendarHomeView.CalendarViewType
    @Binding var selectedEvent: CalendarEvent?

    @Namespace private var animation
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let daySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
                .padding(.top, 10)

            // Day labels
            HStack(spacing: 0) {
                ForEach(daySymbols, id: \.self) { symbol in
                    Text(symbol.prefix(1))
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Calendar Grid
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
                    .padding(.horizontal, 0)
                    .background(Color(.systemBackground))
                    .ignoresSafeArea(edges: .horizontal)

                    Divider()

                    // Selected Day's Events
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
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Text(monthYearLabel)
                .font(.largeTitle.bold())

            Spacer()

            HStack(spacing: 20) {
                Button {
                    withAnimation {
                        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                }

                Button {
                    withAnimation {
                        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.bold())
                }
            }
        }
        .padding(.horizontal)
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
