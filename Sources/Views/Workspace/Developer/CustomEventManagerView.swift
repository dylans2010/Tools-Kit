import SwiftUI

struct CustomEventManagerView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var selectedAppID: UUID?
    @State private var showingAdd = false
    @State private var newEventName = ""

    var events: [CustomEventRecord] {
        store.customEventDefinitions.filter { $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Select App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Event Definitions") {
                if selectedAppID == nil {
                    Text("Select an app to manage custom events.").foregroundStyle(.secondary)
                } else if events.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("No custom events defined for this app.").foregroundStyle(.secondary)
                        Button("Define First Event") { showingAdd = true }
                            .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(events) { event in
                        VStack(alignment: .leading) {
                            Text(event.eventName).font(.subheadline.bold())
                            Text(event.timestamp.formatted()).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: deleteEvents)

                    Button("Define New Event") { showingAdd = true }
                        .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Custom Events")
        .sheet(isPresented: $showingAdd) {
            addEventSheet
        }
    }

    private var addEventSheet: some View {
        NavigationStack {
            Form {
                TextField("Event Name", text: $newEventName)
            }
            .navigationTitle("New Custom Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { addEvent() }
                        .disabled(newEventName.isEmpty)
                }
            }
        }
    }

    private func addEvent() {
        guard let appID = selectedAppID else { return }
        let event = CustomEventRecord(appID: appID, eventName: newEventName)
        var current = store.customEventDefinitions
        current.append(event)
        store.saveCustomEvents(current)
        newEventName = ""
        showingAdd = false
    }

    private func deleteEvents(at offsets: IndexSet) {
        var current = store.customEventDefinitions
        let toDelete = offsets.map { events[$0].id }
        current.removeAll { toDelete.contains($0.id) }
        store.saveCustomEvents(current)
    }
}
