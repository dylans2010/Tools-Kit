import SwiftUI

struct WebhookManagerView: View {
    @ObservedObject var webhookService = WebhookService.shared
    @ObservedObject var appService = DeveloperAppService.shared
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
                        EmptyStateView(icon: "bolt.horizontal.fill", title: "No Endpoints", message: "Register a webhook endpoint to receive real-time event notifications for your applications.")
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

            HStack(spacing: 32) {
                VStack(alignment: .leading) {
                    Text("1,242").font(.title3.bold())
                    Text("Events (24h)").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                }
                VStack(alignment: .leading) {
                    Text("142ms").font(.title3.bold())
                    Text("Avg Latency").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding()
    }

    private func endpointCard(_ endpoint: WebhookEndpoint) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(endpoint.url).font(.subheadline.bold()).lineLimit(1)
                    if let app = appService.apps.first(where: { $0.id == endpoint.signingSecretKeyID }) { // Use secret key id as fallback or proxy if appID missing
                        Text(app.name).font(.system(size: 9, weight: .bold)).foregroundStyle(Color.accentColor)
                    }
                }
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
                Text("Subscribed Events").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                FlowLayout(endpoint.subscribedEvents, spacing: 4) { event in
                    Text(event.rawValue).font(.system(size: 8, design: .monospaced)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
                }
            }

            Divider()

            HStack(spacing: 20) {
                NavigationLink(destination: WebhookDeliveryLogView(endpointID: endpoint.id)) {
                    Label("Delivery Logs", systemImage: "list.bullet.indent").font(.system(size: 10, weight: .bold))
                }

                Spacer()

                Button {
                    testEndpoint(endpoint)
                } label: {
                    Label("Test Delivery", systemImage: "paperplane.fill").font(.system(size: 10, weight: .bold))
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
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var url = "https://"
    @State private var secret = ""
    @State private var selectedAppID: UUID?
    @State private var selectedEvents: Set<String> = ["app.updated", "release.published"]

    let availableEvents = ["app.created", "app.updated", "app.deleted", "release.published", "beta.invited", "incident.created"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Application Context") {
                    Picker("App", selection: $selectedAppID) {
                        Text("Select App").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                }

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
                        guard let _ = selectedAppID else { return }
                        let endpoint = WebhookEndpoint(id: UUID(), url: url, subscribedEvents: [], isActive: true, signingSecretKeyID: UUID())
                        Task {
                            try? await webhookService.createEndpoint(endpoint)
                            await MainActor.run { dismiss() }
                        }
                    }
                    .disabled(url.count < 10 || selectedAppID == nil)
                }
            }
        }
    }
}
