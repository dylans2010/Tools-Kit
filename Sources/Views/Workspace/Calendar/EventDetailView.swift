import SwiftUI

struct EventDetailView: View {
    @State var event: CalendarEvent
    @StateObject private var manager = CalendarManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDelete = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection

                        detailsSection

                        if !event.description.isEmpty {
                            descriptionSection
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }

                ToolbarItemGroup(placement: .confirmationAction) {
                    Button { showingEdit = true } label: { Image(systemName: "pencil") }
                    Button(role: .destructive) { showingDelete = true } label: { Image(systemName: "trash") }
                }
            }
            .sheet(isPresented: $showingEdit) {
                CreateEventView(existingEvent: event) { updated in
                    manager.updateEvent(updated)
                    event = updated
                }
            }
            .confirmationDialog("Delete Event", isPresented: $showingDelete) {
                Button("Delete", role: .destructive) {
                    manager.deleteEvent(event)
                    dismiss()
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(event.title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            HStack {
                Text(event.priority.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: event.priority.color)?.opacity(0.2) ?? .blue.opacity(0.2), in: Capsule())
                    .foregroundStyle(Color(hex: event.priority.color) ?? Color.blue)

                Spacer()

                Text(event.date.formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var detailsSection: some View {
        VStack(spacing: 1) {
            detailRow(icon: "clock", label: "Starts", value: event.startTime.formatted(date: .omitted, time: .shortened))
            Divider().background(Color(.secondarySystemBackground))
            detailRow(icon: "clock.fill", label: "Ends", value: event.endTime.formatted(date: .omitted, time: .shortened))

            if !event.location.isEmpty {
                Divider().background(Color(.secondarySystemBackground))
                detailRow(icon: "mappin.and.ellipse", label: "Location", value: event.location)
            }
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Agenda & Notes", systemImage: "text.alignleft")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            Text(event.description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).frame(width: 24).foregroundStyle(.primary)
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
        .padding()
    }
}
