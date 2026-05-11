import SwiftUI

struct ConnectorWebhookManagerView: View {
    @State private var webhooks: [WebhookConfig] = []
    @State private var showingCreateSheet = false
    @State private var newURL = ""
    @State private var newEvent = ""

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
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        Image(systemName: index % 4 == 3 ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(index % 4 == 3 ? .red : .green)
                        VStack(alignment: .leading) {
                            Text("Event delivered")
                                .font(.caption)
                            Text(Date().addingTimeInterval(Double(-index) * 3600).formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(index % 4 == 3 ? "500" : "200")
                            .font(.caption.monospaced())
                            .foregroundStyle(index % 4 == 3 ? .red : .green)
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
        webhooks = [
            WebhookConfig(url: "https://api.example.com/webhooks/push", event: "repository.push", isActive: true, deliveryCount: 142),
            WebhookConfig(url: "https://api.example.com/webhooks/pr", event: "pull_request.opened", isActive: true, deliveryCount: 67),
            WebhookConfig(url: "https://api.example.com/webhooks/deploy", event: "deployment.completed", isActive: false, deliveryCount: 23),
        ]
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
