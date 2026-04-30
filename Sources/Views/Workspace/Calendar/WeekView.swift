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
        ZStack {
            Color.workspaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                weekPicker
                    .padding()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(weekDays, id: \.self) { day in
                            WeekDayRow(day: day, manager: manager, selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var weekPicker: some View {
        HStack {
            Button { selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(weekRangeLabel).font(.headline)
            Spacer()
            Button { selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
        .background(Color.workspaceSurface, in: Capsule())
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
    private var dayEvents: [CalendarEvent] { manager.events(on: day) }
    private var isToday: Bool { calendar.isDateInToday(day) }
    private var isSelected: Bool { calendar.isDate(day, inSameDayAs: selectedDate) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .center, spacing: 2) {
                    Text(day.formatted(.dateTime.weekday(.abbreviated))).font(.caption2.bold()).foregroundStyle(.secondary)
                    Text(day.formatted(.dateTime.day())).font(.title3.bold()).foregroundStyle(isToday ? .blue : .white)
                }
                .frame(width: 45)
                .padding(8)
                .background(isToday ? Color.blue.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 12))

                if dayEvents.isEmpty {
                    Text("No events").font(.caption).foregroundStyle(.secondary).padding(.leading, 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(dayEvents) { event in
                                Button { selectedEvent = event } label: {
                                    Text(event.title)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(hex: event.priority.color)?.opacity(0.2) ?? Color.blue.opacity(0.2), in: Capsule())
                                        .foregroundStyle(Color(hex: event.priority.color) ?? .blue)
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(12)
        .background(isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
        .onTapGesture { selectedDate = day }
    }
}
