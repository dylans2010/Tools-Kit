import SwiftUI

struct WebhookManagerView: View {
    @ObservedObject var webhookService = WebhookService.shared
    @State private var showingAddEndpoint = false
    @State private var newUrl = ""
    @State private var selectedEvents: Set<WebhookEventType> = []

    var body: some View {
        List {
            Section("Endpoints") {
                if webhookService.endpoints.isEmpty {
                    EmptyStateView(text: "No webhook endpoints configured.", icon: "antenna.radiowaves.left.and.right")
                } else {
                    ForEach(webhookService.endpoints) { endpoint in
                        NavigationLink(destination: WebhookDetailView(endpointID: endpoint.id)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(endpoint.url).font(.subheadline.bold())
                                Text("\(endpoint.subscribedEvents.count) events subscribed").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteEndpoints)
                }
            }

            Section {
                Button { showingAddEndpoint = true } label: {
                    Label("Add Endpoint", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Webhook Management")
        .sheet(isPresented: $showingAddEndpoint) {
            addEndpointSheet
        }
    }

    private var addEndpointSheet: some View {
        NavigationStack {
            Form {
                Section("Endpoint Configuration") {
                    TextField("Endpoint URL", text: $newUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("Events to Subscribe") {
                    ForEach(WebhookEventType.allCases, id: \.self) { event in
                        Toggle(event.rawValue, isOn: Binding(
                            get: { selectedEvents.contains(event) },
                            set: { if $0 { selectedEvents.insert(event) } else { selectedEvents.remove(event) } }
                        ))
                    }
                }
            }
            .navigationTitle("New Webhook")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddEndpoint = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            try? await webhookService.createEndpoint(url: newUrl, events: Array(selectedEvents))
                            await MainActor.run {
                                newUrl = ""
                                selectedEvents = []
                                showingAddEndpoint = false
                            }
                        }
                    }
                    .disabled(newUrl.isEmpty || selectedEvents.isEmpty)
                }
            }
        }
    }

    private func deleteEndpoints(at offsets: IndexSet) {
        for index in offsets {
            let endpoint = webhookService.endpoints[index]
            Task { try? await webhookService.deleteEndpoint(id: endpoint.id) }
        }
    }
}

struct WebhookDetailView: View {
    let endpointID: UUID
    @ObservedObject var webhookService = WebhookService.shared
    @State private var testStatus: String?
    @State private var isTesting = false

    var endpoint: WebhookEndpoint? {
        webhookService.endpoints.first { $0.id == endpointID }
    }

    var body: some View {
        if let endpoint = endpoint {
            List {
                Section("Configuration") {
                    infoRow(label: "URL", value: endpoint.url)
                    infoRow(label: "Signing Secret", value: "••••••••••••••••")
                    Toggle("Active", isOn: Binding(
                        get: { endpoint.isActive },
                        set: { isActive in
                            var updated = endpoint
                            updated.isActive = isActive
                            Task { try? await webhookService.updateEndpoint(updated) }
                        }
                    ))
                }

                Section("Events") {
                    ForEach(endpoint.subscribedEvents, id: \.self) { event in
                        Text(event.rawValue).font(.subheadline)
                    }
                }

                Section {
                    Button {
                        testWebhook()
                    } label: {
                        if isTesting {
                            ProgressView()
                        } else {
                            Label("Send Test Event", systemImage: "paperplane")
                        }
                    }
                    .disabled(isTesting)

                    if let status = testStatus {
                        Text(status).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Webhook Details")
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
        .font(.subheadline)
    }

    private func testWebhook() {
        isTesting = true
        Task {
            let (code, message) = try await webhookService.testDelivery(endpointID: endpointID)
            await MainActor.run {
                isTesting = false
                testStatus = "Last test: \(code) \(message)"
            }
        }
    }
}
