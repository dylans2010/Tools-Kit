import SwiftUI

struct DeveloperWebhookManagerView: View {
    @ObservedObject var webhookService = WebhookService.shared
    @State private var showingAddWebhook = false
    @State private var newWebhookURL = ""
    @State private var selectedEvents: Set<WebhookEventType> = []

    var body: some View {
        List {
            Section {
                if webhookService.endpoints.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No webhooks configured. Add one to receive real-time updates at your endpoint.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(webhookService.endpoints) { webhook in
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
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddWebhook = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAddWebhook) {
            addWebhookSheet
        }
    }

    private func webhookRow(_ webhook: WebhookEndpoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(webhook.url).font(.subheadline.bold()).lineLimit(1)
                Spacer()
                Circle().fill(webhook.isActive ? .green : .gray).frame(width: 8, height: 8)
            }
            Text("\(webhook.subscribedEvents.map { $0.rawValue }.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var addWebhookSheet: some View {
        NavigationStack {
            Form {
                Section("Endpoint URL") {
                    TextField("https://api.yourservice.com/webhook", text: $newWebhookURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section("Events") {
                    ForEach(WebhookEventType.allCases, id: \.self) { event in
                        Toggle(event.rawValue, isOn: binding(for: event))
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

    private func binding(for event: WebhookEventType) -> Binding<Bool> {
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
        Task {
            try? await webhookService.createEndpoint(url: newWebhookURL, events: Array(selectedEvents))
            await MainActor.run {
                showingAddWebhook = false
                newWebhookURL = ""
                selectedEvents = []
            }
        }
    }

    private func deleteWebhook(at offsets: IndexSet) {
        for index in offsets {
            let webhook = webhookService.endpoints[index]
            Task { try? await webhookService.deleteEndpoint(id: webhook.id) }
        }
    }
}
