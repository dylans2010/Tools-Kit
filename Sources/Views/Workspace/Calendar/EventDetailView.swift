import SwiftUI

struct EventDetailView: View {
    @State var event: CalendarEvent
    @ObservedObject var manager: CalendarManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDelete = false

    private var priorityColor: Color { Color(hex: event.priority.colorHex) ?? .accentColor }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Priority banner
                HStack {
                    Circle().fill(priorityColor).frame(width: 12, height: 12)
                    Text(event.priority.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(priorityColor)
                    Spacer()
                    Text(event.formattedTimeRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Title
                Text(event.title)
                    .font(.title2.bold())
                    .padding(.horizontal)

                // Description
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                // Metadata
                VStack(spacing: 0) {
                    metaRow(icon: "calendar", label: "Date", value: DateFormatter.localizedString(from: event.date, dateStyle: .full, timeStyle: .none))
                    Divider().padding(.leading, 52)
                    metaRow(icon: "clock", label: "Time", value: event.formattedTimeRange)
                    Divider().padding(.leading, 52)
                    metaRow(icon: "timer", label: "Duration", value: "\(event.durationMinutes) min")
                    if !event.location.isEmpty {
                        Divider().padding(.leading, 52)
                        metaRow(icon: "mappin.circle", label: "Location", value: event.location)
                    }
                    Divider().padding(.leading, 52)
                    metaRow(icon: "clock.badge", label: "Created", value: DateFormatter.localizedString(from: event.createdAt, dateStyle: .medium, timeStyle: .short))
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.horizontal)

                // Delete button
                Button(role: .destructive) {
                    showingDelete = true
                } label: {
                    Label("Delete Event", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit, onDismiss: {
            if let updated = manager.events.first(where: { $0.id == event.id }) {
                event = updated
            }
        }) {
            CreateEventView(manager: manager, editingEvent: event, initialDate: event.date)
        }
        .confirmationDialog("Delete Event", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                manager.deleteEvent(event)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(event.title)\"?")
        }
    }

    private func metaRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.accentColor).frame(width: 24)
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).multilineTextAlignment(.trailing)
        }
        .padding()
    }
}
