import SwiftUI

struct CalendarAgendaView: View {
    @StateObject private var manager = CalendarManager.shared
    @Binding var selectedEvent: CalendarEvent?
    @State private var showingCreate = false

    private var groupedEvents: [(String, [CalendarEvent])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none

        let upcoming = manager.events.filter { $0.startTime >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.startTime < $1.startTime }

        var grouped: [String: [CalendarEvent]] = [:]
        for event in upcoming {
            let key = formatter.string(from: event.date)
            grouped[key, default: []].append(event)
        }
        return grouped.sorted { a, b in
            let df = DateFormatter()
            df.dateStyle = .full
            let da = df.date(from: a.key) ?? Date()
            let db = df.date(from: b.key) ?? Date()
            return da < db
        }
    }

    var body: some View {
        ScrollView {
            if manager.events.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No Events",
                    message: "Your upcoming events will appear here.",
                    action: { showingCreate = true },
                    actionLabel: "Add Event"
                )
                .padding(.top, 40)
            } else if groupedEvents.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "All Caught Up",
                    message: "No upcoming events scheduled."
                )
                .padding(.top, 40)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedEvents, id: \.0) { dateLabel, events in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(dateLabel)
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 16)
                                .padding(.bottom, 8)

                            ForEach(events) { event in
                                Button {
                                    selectedEvent = event
                                } label: {
                                    EventAgendaRow(event: event)
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                CreateEventView(prefilledDate: Date()) { event in
                    manager.addEvent(event)
                }
            }
        }
    }
}

struct EventAgendaRow: View {
    let event: CalendarEvent

    private var eventColor: Color {
        Color(hex: event.priority.color) ?? .blue
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeString(event.startTime))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(timeString(event.endTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 52)

            Rectangle()
                .fill(eventColor)
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                if !event.location.isEmpty {
                    Label(event.location, systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}
