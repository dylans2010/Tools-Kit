import SwiftUI

struct CalendarWeekView: View {
    @StateObject private var manager = CalendarManager.shared
    @Binding var selectedDate: Date
    @Binding var selectedEvent: CalendarEvent?

    private let calendar = Calendar.current

    private var weekDays: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }

    var body: some View {
        VStack(spacing: 0) {
            weekHeader

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(weekDays, id: \.self) { day in
                        WeekDayRow(day: day, manager: manager, selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var weekHeader: some View {
        HStack {
            Button {
                selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(weekRangeLabel)
                .font(.subheadline.bold())
            Spacer()
            Button {
                selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var weekRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        return "\(f.string(from: first)) – \(f.string(from: last))"
    }
}

struct WeekDayRow: View {
    let day: Date
    @ObservedObject var manager: CalendarManager
    @Binding var selectedDate: Date
    @Binding var selectedEvent: CalendarEvent?

    private let calendar = Calendar.current

    var dayEvents: [CalendarEvent] { manager.events(on: day) }
    var isToday: Bool { calendar.isDateInToday(day) }
    var isSelected: Bool { calendar.isDate(day, inSameDayAs: selectedDate) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                selectedDate = day
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(isToday ? Color.accentColor : (isSelected ? Color.accentColor.opacity(0.15) : Color.clear))
                            .frame(width: 34, height: 34)
                        VStack(spacing: 1) {
                            Text(dayName(day))
                                .font(.caption2)
                                .textCase(.uppercase)
                                .foregroundColor(isToday ? .white : .secondary)
                            Text(dayNumber(day))
                                .font(.caption.bold())
                                .foregroundColor(isToday ? .white : .primary)
                        }
                    }

                    if dayEvents.isEmpty {
                        Text("No events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(dayEvents.count) event\(dayEvents.count == 1 ? "" : "s")")
                            .font(.caption.bold())
                            .foregroundColor(.accentColor)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            if isSelected && !dayEvents.isEmpty {
                VStack(spacing: 4) {
                    ForEach(dayEvents) { event in
                        Button {
                            selectedEvent = event
                        } label: {
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: event.priority.color) ?? .blue)
                                    .frame(width: 3, height: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title)
                                        .font(.caption.bold())
                                    Text(event.formattedTimeRange)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 44)
            }
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.05) : Color.clear)
    }

    private func dayName(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private func dayNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
}
