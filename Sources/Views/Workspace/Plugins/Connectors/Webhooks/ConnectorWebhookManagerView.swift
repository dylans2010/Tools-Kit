import SwiftUI

struct ConnectorWebhookManagerView: View {
    @State private var webhooks: [WebhookConfig] = []
    @State private var showingCreateSheet = false
    @State private var newURL = ""
    @State private var newEvent = ""
    @State private var deliveryLogs: [WebhookDeliveryLog] = []

    var body: some View {
        List {
            Section("Active Webhooks") {
                if webhooks.filter(\.isActive).isEmpty {
                    Text("No active webhooks")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(webhooks.filter(\.isActive)) { webhook in
                        webhookRow(webhook)
                    }
                }
            }

            Section("Inactive Webhooks") {
                ForEach(webhooks.filter { !$0.isActive }) { webhook in
                    webhookRow(webhook)
                }
            }

            Section("Delivery Log") {
                if deliveryLogs.isEmpty {
                    Text("No deliveries yet")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ForEach(deliveryLogs) { log in
                        HStack {
                            Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(log.success ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(log.event)
                                    .font(.caption)
                                Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(log.statusCode)")
                                .font(.caption.monospaced())
                                .foregroundStyle(log.success ? .green : .red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Webhook Manager")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingCreateSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            NavigationStack {
                Form {
                    Section("Endpoint") {
                        TextField("Webhook URL", text: $newURL)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                    }
                    Section("Event") {
                        TextField("Event Name", text: $newEvent)
                    }
                }
                .navigationTitle("Create Webhook")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCreateSheet = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            webhooks.append(WebhookConfig(url: newURL, event: newEvent, isActive: true))
                            newURL = ""
                            newEvent = ""
                            showingCreateSheet = false
                        }
                        .disabled(newURL.isEmpty || newEvent.isEmpty)
                    }
                }
            }
        }
        .task { loadWebhooks() }
    }

    private func webhookRow(_ webhook: WebhookConfig) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: webhook.isActive ? "bolt.fill" : "bolt.slash")
                    .foregroundStyle(webhook.isActive ? .green : .secondary)
                Text(webhook.event)
                    .font(.headline)
            }
            Text(webhook.url)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack {
                Text("Deliveries: \(webhook.deliveryCount)")
                Spacer()
                Text("Created \(webhook.createdAt.formatted(date: .abbreviated, time: .omitted))")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func loadWebhooks() {
        // Webhooks are user-configured; start empty until the user creates their own.
    }
}

private struct WebhookConfig: Identifiable {
    let id = UUID()
    let url: String
    let event: String
    let isActive: Bool
    let deliveryCount: Int
    let createdAt: Date

    init(url: String, event: String, isActive: Bool, deliveryCount: Int = 0) {
        self.url = url
        self.event = event
        self.isActive = isActive
        self.deliveryCount = deliveryCount
        self.createdAt = Date()
    }
}

private struct WebhookDeliveryLog: Identifiable {
    let id = UUID()
    let event: String
    let timestamp: Date
    let statusCode: Int
    let success: Bool
}
