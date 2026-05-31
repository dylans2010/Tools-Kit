import SwiftUI

struct DeveloperWebhookManagerView: View {
    @ObservedObject var webhookService = WebhookService.shared
    @State private var showingAddEndpoint = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                webhookHealthHeader

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Endpoints").font(.headline)
                        Spacer()
                        Button { showingAddEndpoint = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                    }

                    if webhookService.endpoints.isEmpty {
                        EmptyStateView(icon: "bolt.horizontal.fill", title: "No Endpoints", message: "Register a webhook endpoint to receive real-time event notifications.")
                    } else {
                        ForEach(webhookService.endpoints) { endpoint in
                            endpointCard(endpoint)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Webhooks")
        .sheet(isPresented: $showingAddEndpoint) {
            AddWebhookEndpointSheet()
        }
    }

    private var webhookHealthHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Delivery Status").font(.headline)
                    Text("99.8% Success Rate").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "bolt.fill").foregroundStyle(.yellow).font(.title2)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("1,242").font(.title3.bold())
                    Text("Events (24h)").font(.caption2).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading) {
                    Text("142ms").font(.title3.bold())
                    Text("Avg Latency").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    private func endpointCard(_ endpoint: WebhookEndpoint) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(endpoint.url).font(.subheadline.bold()).lineLimit(1)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { endpoint.isActive },
                    set: { val in
                        var updated = endpoint
                        updated.isActive = val
                        Task { try? await webhookService.updateEndpoint(updated) }
                    }
                )).labelsHidden().scaleEffect(0.8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Events:").font(.caption2.bold()).foregroundStyle(.secondary)
                Text(endpoint.subscribedEvents.joined(separator: ", ")).font(.system(size: 9)).foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                NavigationLink(destination: WebhookDeliveryLogView(endpointID: endpoint.id)) {
                    Text("Delivery Logs").font(.system(size: 10, weight: .bold))
                }
                Spacer()
                Button {
                    testEndpoint(endpoint)
                } label: {
                    Text("Test Delivery").font(.system(size: 10, weight: .bold))
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func testEndpoint(_ endpoint: WebhookEndpoint) {
        Task {
            try? await webhookService.testDelivery(endpointID: endpoint.id)
        }
    }
}

struct AddWebhookEndpointSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var webhookService = WebhookService.shared

    @State private var url = "https://"
    @State private var secret = ""
    @State private var selectedEvents: Set<String> = ["app.updated", "release.published"]

    let availableEvents = ["app.created", "app.updated", "app.deleted", "release.published", "beta.invited", "incident.created"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Endpoint Configuration") {
                    TextField("Endpoint URL", text: $url).keyboardType(.URL).autocapitalization(.none)
                    TextField("Signing Secret (Optional)", text: $secret).autocapitalization(.none)
                }

                Section("Subscribed Events") {
                    ForEach(availableEvents, id: \.self) { event in
                        Toggle(event, isOn: Binding(
                            get: { selectedEvents.contains(event) },
                            set: { val in
                                if val { selectedEvents.insert(event) }
                                else { selectedEvents.remove(event) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("New Webhook")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Register") {
                        let endpoint = WebhookEndpoint(id: UUID(), url: url, secret: secret, isActive: true, subscribedEvents: Array(selectedEvents))
                        Task {
                            try? await webhookService.createEndpoint(endpoint)
                            await MainActor.run { dismiss() }
                        }
                    }
                    .disabled(url.count < 10)
                }
            }
        }
    }
}
