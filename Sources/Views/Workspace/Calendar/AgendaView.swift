import SwiftUI

struct AgendaView: View {
    @ObservedObject var manager: CalendarManager
    @Binding var selectedEvent: CalendarEvent?

    private var groupedEvents: [(String, [CalendarEvent])] {
        let upcoming = manager.upcomingEvents
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var groups: [String: [CalendarEvent]] = [:]
        for event in upcoming {
            let key = formatter.string(from: event.date)
            groups[key, default: []].append(event)
        }
        return groups.sorted { $0.key < $1.key }.map { key, events in
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            let date = formatter.date(from: key) ?? Date()
            return (displayFormatter.string(from: date), events)
        }
    }

    var body: some View {
        ScrollView {
            if groupedEvents.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No Upcoming Events",
                    message: "Add events to see your agenda."
                )
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(groupedEvents, id: \.0) { dateStr, events in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(dateStr)
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(events) { event in
                                Button { selectedEvent = event } label: {
                                    HStack(spacing: 12) {
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

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(event.priority.rawValue)
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background((Color(hex: event.priority.colorHex) ?? .accentColor).opacity(0.15))
                                                .foregroundColor(Color(hex: event.priority.colorHex) ?? .accentColor)
                                                .cornerRadius(8)
                                            Text("\(event.durationMinutes)m")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(14)
                                    .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
