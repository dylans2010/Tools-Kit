import SwiftUI

struct EventDetailView: View {
    @State var event: CalendarEvent
    @StateObject private var manager = CalendarManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDelete = false

    private var eventColor: Color {
        Color(hex: event.priority.color) ?? .blue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                detailsCard
                if !event.description.isEmpty {
                    descriptionCard
                }
            }
            .padding()
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { showingEdit = true } label: {
                    Image(systemName: "pencil")
                }
                Button(role: .destructive) {
                    showingDelete = true
                } label: {
                    Image(systemName: "trash")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                CreateEventView(existingEvent: event) { updated in
                    manager.updateEvent(updated)
                    event = updated
                }
            }
        }
        .confirmationDialog("Delete Event", isPresented: $showingDelete) {
            Button("Delete Event", role: .destructive) {
                manager.deleteEvent(event)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(event.title)\"?")
        }
        .onReceive(manager.$events) { events in
            if let updated = events.first(where: { $0.id == event.id }) {
                event = updated
            }
        }
    }

    private var headerCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(eventColor.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: "calendar")
                            .font(.system(size: 22))
                            .foregroundColor(eventColor)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.title3.bold())
                        Label(event.priority.rawValue + " Priority", systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundColor(eventColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private var detailsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Details")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)

                DetailRow(icon: "calendar", label: "Date", value: formatDate(event.date))
                DetailRow(icon: "clock", label: "Start", value: formatTime(event.startTime))
                DetailRow(icon: "clock.badge.checkmark", label: "End", value: formatTime(event.endTime))

                let duration = Int(event.duration / 60)
                DetailRow(icon: "timer", label: "Duration", value: "\(duration) min")

                if !event.location.isEmpty {
                    DetailRow(icon: "location.fill", label: "Location", value: event.location)
                }
            }
            .padding()
        }
    }

    private var descriptionCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                Text(event.description)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }
}
