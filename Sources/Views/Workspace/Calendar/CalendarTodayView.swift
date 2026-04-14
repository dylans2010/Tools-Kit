import SwiftUI

struct CalendarTodayView: View {
    @StateObject private var manager = CalendarManager.shared
    @Binding var selectedDate: Date
    @Binding var selectedEvent: CalendarEvent?
    @State private var showingCreate = false

    private let calendar = Calendar.current
    private let hourHeight: CGFloat = 60

    var todayEvents: [CalendarEvent] {
        manager.events(on: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            dateHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if todayEvents.isEmpty {
                        EmptyStateView(
                            icon: "calendar.badge.plus",
                            title: "No Events",
                            message: "Tap the + button to add an event for \(shortDate(selectedDate)).",
                            action: { showingCreate = true },
                            actionLabel: "Add Event"
                        )
                        .padding()
                    } else {
                        timelineView
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                CreateEventView(prefilledDate: selectedDate) { event in
                    manager.addEvent(event)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayName(selectedDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(shortDate(selectedDate))
                    .font(.headline)
            }
            Spacer()
            HStack(spacing: 12) {
                Button {
                    selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.left")
                }
                Button {
                    selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var timelineView: some View {
        VStack(spacing: 0) {
            ForEach(todayEvents) { event in
                Button {
                    selectedEvent = event
                } label: {
                    EventTimelineRow(event: event)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 60)
            }
        }
        .padding(.top, 8)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: date)
    }

    private func dayName(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }
}

struct EventTimelineRow: View {
    let event: CalendarEvent

    private var eventColor: Color {
        Color(hex: event.priority.color) ?? .blue
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline.bold())
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                if !event.location.isEmpty {
                    Label(event.location, systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 12)
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
