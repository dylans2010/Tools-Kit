import SwiftUI

struct CustomEventManagerView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddEvent = false
    @State private var eventName = ""

    @State private var events: [CustomEventDef] = [
        CustomEventDef(name: "user_signup", type: "Conversion"),
        CustomEventDef(name: "item_purchased", type: "Monetization")
    ]

    var body: some View {
        List {
            Section("Event Tracking") {
                Picker("Application", selection: $selectedAppID) {
                    Text("Select App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            if selectedAppID != nil {
                Section("Active Definitions") {
                    if events.isEmpty {
                        EmptyStateView(icon: "bolt.fill", title: "No Events", message: "Define custom events to track specific user behaviors in your application.")
                    } else {
                        ForEach(events) { event in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.name).font(.subheadline.bold()).monospaced()
                                    Text(event.type).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                            }
                        }
                    }
                }

                Section {
                    Button { showingAddEvent = true } label: {
                        Label("Define New Event", systemImage: "plus.circle.fill").font(.subheadline.bold())
                    }
                }
            }
        }
        .navigationTitle("Custom Events")
        .sheet(isPresented: $showingAddEvent) {
            NavigationStack {
                Form {
                    Section("Metadata") {
                        TextField("Event Name (snake_case)", text: $eventName)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }
                .navigationTitle("New Event")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddEvent = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Define") {
                            events.append(CustomEventDef(name: eventName, type: "General"))
                            showingAddEvent = false
                            eventName = ""
                        }
                        .disabled(eventName.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }
}

struct CustomEventDef: Identifiable {
    let id = UUID()
    let name: String
    let type: String
}
