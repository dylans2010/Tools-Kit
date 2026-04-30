import SwiftUI

struct CalendarAgendaView: View {
    @StateObject private var manager = CalendarManager.shared
    @Binding var selectedEvent: CalendarEvent?
    @State private var showingCreate = false

    private var groupedEvents: [(Date, [CalendarEvent])] {
        let calendar = Calendar.current
        let upcoming = manager.events.filter { $0.startTime >= calendar.startOfDay(for: Date()) }

        var dict: [Date: [CalendarEvent]] = [:]
        for event in upcoming {
            let day = calendar.startOfDay(for: event.date)
            dict[day, default: []].append(event)
        }

        return dict.sorted { $0.key < $1.key }
    }

    var body: some View {
        ZStack {
            Color.workspaceBackground.ignoresSafeArea()

            ScrollView {
                if manager.events.isEmpty {
                    emptyState
                } else {
                    LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedEvents, id: \.0) { date, events in
                            Section(header: dateHeader(date)) {
                                ForEach(events) { event in
                                    EventAgendaRow(event: event)
                                        .onTapGesture { selectedEvent = event }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func dateHeader(_ date: Date) -> some View {
        HStack {
            Text(date.formatted(.dateTime.weekday().day().month()))
                .font(.subheadline.bold())
                .foregroundStyle(.blue)
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color.workspaceBackground)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Clear Schedule")
                .font(.headline)
            Text("Your agenda is open. Use AI to fill it with meaningful work.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

struct EventAgendaRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(event.startTime.formatted(.dateTime.hour().minute()))
                    .font(.caption.bold())
                Text(event.endTime.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline.bold())
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Circle()
                .fill(Color(hex: event.priority.color) ?? .blue)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}
