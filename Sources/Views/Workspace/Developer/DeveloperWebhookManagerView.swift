import SwiftUI

struct DeveloperWebhookManagerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAddWebhook = false
    @State private var newWebhookURL = ""
    @State private var selectedEvents: Set<String> = []

    let availableEvents = ["app.installed", "app.updated", "user.authorized", "payment.succeeded", "log.error"]

    var body: some View {
        List {
            Section {
                if store.webhooks.isEmpty {
                    Text("No webhooks configured. Add one to receive real-time updates.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.webhooks) { webhook in
                        webhookRow(webhook)
                    }
                    .onDelete(perform: deleteWebhook)
                }
            } header: {
                Text("Active Webhooks")
            }
        }
        .navigationTitle("Webhooks")
        .toolbar {
            Button { showingAddWebhook = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showingAddWebhook) {
            NavigationStack {
                Form {
                    Section("Endpoint URL") {
                        TextField("https://api.yourservice.com/webhook", text: $newWebhookURL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    Section("Events") {
                        ForEach(availableEvents, id: \.self) { event in
                            Toggle(event, isOn: binding(for: event))
                        }
                    }
                }
                .navigationTitle("Add Webhook")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddWebhook = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addWebhook() }
                            .disabled(newWebhookURL.isEmpty || selectedEvents.isEmpty)
                    }
                }
            }
        }
    }

    private func webhookRow(_ webhook: DeveloperWebhook) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(webhook.url).font(.subheadline.bold()).lineLimit(1)
                Spacer()
                Circle().fill(webhook.isActive ? .green : .gray).frame(width: 8, height: 8)
            }
            Text("\(webhook.events.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func binding(for event: String) -> Binding<Bool> {
        Binding(
            get: { selectedEvents.contains(event) },
            set: { isSelected in
                if isSelected {
                    selectedEvents.insert(event)
                } else {
                    selectedEvents.remove(event)
                }
            }
        )
    }

    private func addWebhook() {
        let webhook = DeveloperWebhook(url: newWebhookURL, events: Array(selectedEvents), secret: UUID().uuidString)
        var current = store.webhooks
        current.append(webhook)
        store.saveWebhooks(current)
        showingAddWebhook = false
        newWebhookURL = ""
        selectedEvents = []
    }

    private func deleteWebhook(at offsets: IndexSet) {
        var current = store.webhooks
        current.remove(atOffsets: offsets)
        store.saveWebhooks(current)
    }
}
