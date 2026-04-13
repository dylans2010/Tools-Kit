import SwiftUI

struct CalendarTodayView: View {
    @ObservedObject var manager: CalendarManager
    @Binding var selectedDate: Date
    @Binding var selectedEvent: CalendarEvent?

    private var todayEvents: [CalendarEvent] {
        manager.events(on: selectedDate)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                dateHeader
                if todayEvents.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.checkmark",
                        title: "No Events",
                        message: "Nothing scheduled for today."
                    )
                } else {
                    timelineView
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedDate, style: .date)
                .font(.title2.bold())
            Text("\(todayEvents.count) event\(todayEvents.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }

    private var timelineView: some View {
        VStack(spacing: 0) {
            ForEach(todayEvents) { event in
                Button {
                    selectedEvent = event
                } label: {
                    HStack(alignment: .top, spacing: 14) {
                        Text(shortTime(event.startTime))
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .frame(width: 56, alignment: .trailing)

                        Rectangle()
                            .fill(Color(hex: event.priority.colorHex) ?? .accentColor)
                            .frame(width: 4)
                            .cornerRadius(2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text(event.formattedTimeRange)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if !event.location.isEmpty {
                                Label(event.location, systemImage: "mappin.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.trailing)

                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 86)
            }
        }
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
