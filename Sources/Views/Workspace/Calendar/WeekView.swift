import SwiftUI

struct WeekView: View {
    @ObservedObject var manager: CalendarManager
    @Binding var selectedDate: Date
    @Binding var selectedEvent: CalendarEvent?

    private var weekDays: [Date] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                weekHeader
                ForEach(weekDays, id: \.self) { day in
                    dayColumn(for: day)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var weekHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(day)
                    Button { selectedDate = day } label: {
                        VStack(spacing: 4) {
                            Text(dayName(day)).font(.caption).foregroundColor(.secondary)
                            ZStack {
                                Circle()
                                    .fill(isToday ? Color.accentColor : (isSelected ? Color.accentColor.opacity(0.3) : Color.clear))
                                    .frame(width: 34, height: 34)
                                Text(dayNumber(day))
                                    .font(.subheadline.bold())
                                    .foregroundColor(isToday ? .white : .primary)
                            }
                            let count = manager.events(on: day).count
                            if count > 0 {
                                Circle().fill(Color.accentColor).frame(width: 5, height: 5)
                            } else {
                                Circle().fill(Color.clear).frame(width: 5, height: 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func dayColumn(for day: Date) -> some View {
        let events = manager.events(on: day)
        guard !events.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text(dayLabel(day))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                ForEach(events) { event in
                    Button { selectedEvent = event } label: {
                        HStack(spacing: 10) {
                            Rectangle()
                                .fill(Color(hex: event.priority.colorHex) ?? .accentColor)
                                .frame(width: 3)
                                .cornerRadius(2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title).font(.subheadline.bold()).lineLimit(1)
                                Text(event.formattedTimeRange).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
            }
        )
    }

    private func dayName(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private func dayNumber(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }
}
