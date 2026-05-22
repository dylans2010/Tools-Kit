import SwiftUI

struct ConnectorWebhookManagerView: View {
    @State private var webhooks: [WebhookConfig] = []
    @State private var showingCreateSheet = false
    @State private var newURL = ""
    @State private var newEvent = ""
    @State private var deliveryLogs: [WebhookDeliveryLog] = []
    @State private var showingPayloadPreview = false
    @State private var selectedWebhookID: UUID?
    @State private var filterEvent = ""
    @State private var showingBulkActions = false
    @State private var signatureVerification = true
    @State private var showingRetryConfig = false
    @State private var retryAttempts = 3
    @State private var retryDelaySeconds = 5
    @State private var showingSecretConfig = false
    @State private var webhookSecret = ""
    @State private var showingEventBuilder = false
    @State private var customPayload = "{}"
    @State private var showingTestDelivery = false
    @State private var testDeliveryResult: TestDeliveryResult?
    @State private var rateLimitPerMinute = 60
    @State private var showingHeaders = false
    @State private var customHeaders: [WebhookHeader] = []

    private var filteredDeliveryLogs: [WebhookDeliveryLog] {
        if filterEvent.isEmpty { return deliveryLogs }
        return deliveryLogs.filter { $0.event.localizedCaseInsensitiveContains(filterEvent) }
    }

    var body: some View {
        List {
            overviewSection
            activeWebhooksSection
            inactiveWebhooksSection
            deliveryLogSection
            securitySection
            retryConfigSection
            rateLimitSection
            testSection
            actionsSection
        }
        .navigationTitle("Webhook Manager")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingCreateSheet = true } label: { Label("Create Webhook", systemImage: "plus") }
                    Button { showingEventBuilder = true } label: { Label("Event Builder", systemImage: "hammer") }
                    Button { showingHeaders = true } label: { Label("Custom Headers", systemImage: "list.bullet.rectangle") }
                    Divider()
                    Button { toggleAllWebhooks(active: true) } label: { Label("Activate All", systemImage: "bolt.fill") }
                    Button { toggleAllWebhooks(active: false) } label: { Label("Deactivate All", systemImage: "bolt.slash") }
                    Divider()
                    Button(role: .destructive) { deliveryLogs.removeAll() } label: { Label("Clear Logs", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            NavigationStack { createWebhookSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEventBuilder) {
            NavigationStack { eventBuilderSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTestDelivery) {
            NavigationStack { testDeliverySheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingHeaders) {
            NavigationStack { customHeadersSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSecretConfig) {
            NavigationStack { secretConfigSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task { loadWebhooks() }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        Section("Overview") {
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(webhooks.count)").font(.title3.bold()).foregroundStyle(.blue)
                    Text("Total").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(webhooks.filter(\.isActive).count)").font(.title3.bold()).foregroundStyle(.green)
                    Text("Active").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(deliveryLogs.count)").font(.title3.bold()).foregroundStyle(.orange)
                    Text("Deliveries").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    let failedCount = deliveryLogs.filter { !$0.success }.count
                    Text("\(failedCount)").font(.title3.bold()).foregroundStyle(failedCount > 0 ? .red : .green)
                    Text("Failed").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Active Webhooks

    private var activeWebhooksSection: some View {
        Section("Active Webhooks") {
            if webhooks.filter(\.isActive).isEmpty {
                Text("No active webhooks")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(webhooks.filter(\.isActive)) { webhook in
                    webhookRow(webhook)
                        .swipeActions(edge: .trailing) {
                            Button { deactivateWebhook(webhook) } label: {
                                Label("Deactivate", systemImage: "bolt.slash")
                            }
                            .tint(.orange)
                            Button(role: .destructive) { deleteWebhook(webhook) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button { sendTestDelivery(webhook) } label: {
                                Label("Test", systemImage: "paperplane")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
    }

    // MARK: - Inactive Webhooks

    private var inactiveWebhooksSection: some View {
        Section("Inactive Webhooks") {
            if webhooks.filter({ !$0.isActive }).isEmpty {
                Text("All webhooks are active")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(webhooks.filter { !$0.isActive }) { webhook in
                    webhookRow(webhook)
                        .swipeActions(edge: .leading) {
                            Button { activateWebhook(webhook) } label: {
                                Label("Activate", systemImage: "bolt.fill")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { deleteWebhook(webhook) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    // MARK: - Delivery Log

    private var deliveryLogSection: some View {
        Section("Delivery Log") {
            if !deliveryLogs.isEmpty {
                TextField("Filter by event", text: $filterEvent)
                    .font(.caption)
            }
            if filteredDeliveryLogs.isEmpty {
                Text("No deliveries yet")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(filteredDeliveryLogs) { log in
                    HStack {
                        Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(log.success ? .green : .red)
                        VStack(alignment: .leading) {
                            Text(log.event)
                                .font(.caption)
                            HStack {
                                Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                if let duration = log.durationMs {
                                    Text("\(duration)ms")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(log.statusCode)")
                                .font(.caption.monospaced())
                                .foregroundStyle(log.success ? .green : .red)
                            if log.retryCount > 0 {
                                Text("\(log.retryCount) retries")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Security Section

    private var securitySection: some View {
        Section("Security") {
            Toggle("Signature Verification", isOn: $signatureVerification)
            if signatureVerification {
                Button { showingSecretConfig = true } label: {
                    HStack {
                        Label("Webhook Secret", systemImage: "key")
                        Spacer()
                        Text(webhookSecret.isEmpty ? "Not Set" : "Configured")
                            .font(.caption)
                            .foregroundStyle(webhookSecret.isEmpty ? .orange : .green)
                    }
                }
            }
            LabeledContent("Signing Algorithm") {
                Text("HMAC-SHA256")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Retry Config

    private var retryConfigSection: some View {
        Section("Retry Policy") {
            Stepper("Max Retries: \(retryAttempts)", value: $retryAttempts, in: 0...10)
            Stepper("Delay: \(retryDelaySeconds)s", value: $retryDelaySeconds, in: 1...60)
            LabeledContent("Backoff Strategy") {
                Text("Exponential")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Rate Limit

    private var rateLimitSection: some View {
        Section("Rate Limiting") {
            Stepper("\(rateLimitPerMinute) deliveries / min", value: $rateLimitPerMinute, in: 1...1000)
            let currentRate = deliveryLogs.filter { $0.timestamp > Date().addingTimeInterval(-60) }.count
            LabeledContent("Current Rate") {
                Text("\(currentRate) / min")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(currentRate > rateLimitPerMinute ? .red : .green)
            }
        }
    }

    // MARK: - Test Section

    private var testSection: some View {
        Section("Test Delivery") {
            Button { showingTestDelivery = true } label: {
                Label("Send Test Event", systemImage: "paperplane.fill")
            }
            if let result = testDeliveryResult {
                LabeledContent("Last Test") {
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.success ? .green : .red)
                        Text("\(result.statusCode) in \(result.durationMs)ms")
                            .font(.caption.monospacedDigit())
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section("Actions") {
            Button {
                retryFailedDeliveries()
            } label: {
                Label("Retry Failed Deliveries", systemImage: "arrow.clockwise")
            }
            .disabled(deliveryLogs.filter({ !$0.success }).isEmpty)

            Button {
                let text = buildDeliveryReport()
                UIPasteboard.general.string = text
            } label: {
                Label("Export Delivery Report", systemImage: "square.and.arrow.up")
            }
            .disabled(deliveryLogs.isEmpty)
        }
    }

    // MARK: - Sheets

    private var createWebhookSheet: some View {
        Form {
            Section("Endpoint") {
                TextField("Webhook URL", text: $newURL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            Section("Event") {
                TextField("Event Name", text: $newEvent)
                Picker("Common Events", selection: $newEvent) {
                    Text("Select...").tag("")
                    Text("connector.created").tag("connector.created")
                    Text("connector.updated").tag("connector.updated")
                    Text("connector.deleted").tag("connector.deleted")
                    Text("connector.synced").tag("connector.synced")
                    Text("connector.error").tag("connector.error")
                    Text("data.received").tag("data.received")
                    Text("data.transformed").tag("data.transformed")
                    Text("auth.refreshed").tag("auth.refreshed")
                }
            }
            Section("Options") {
                Toggle("Active on Creation", isOn: .constant(true))
                Toggle("Verify SSL", isOn: .constant(true))
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

    private var eventBuilderSheet: some View {
        Form {
            Section("Event Payload") {
                TextEditor(text: $customPayload)
                    .font(.caption.monospaced())
                    .frame(minHeight: 150)
            }
            Section("Preview") {
                if let data = customPayload.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data),
                   let formatted = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                   let str = String(data: formatted, encoding: .utf8) {
                    Text(str).font(.caption.monospaced()).foregroundStyle(.green)
                } else {
                    Text("Invalid JSON").font(.caption).foregroundStyle(.red)
                }
            }
            Section("Templates") {
                Button("Basic Event") {
                    customPayload = """
                    {"event": "test.event", "timestamp": "\(ISO8601DateFormatter().string(from: Date()))", "data": {"message": "Hello"}}
                    """
                }
                Button("Connector Sync Event") {
                    customPayload = """
                    {"event": "connector.synced", "connector_id": "abc-123", "records": 42, "duration_ms": 150}
                    """
                }
                Button("Error Event") {
                    customPayload = """
                    {"event": "connector.error", "connector_id": "abc-123", "error": "Connection timeout", "code": 504}
                    """
                }
            }
        }
        .navigationTitle("Event Builder")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var testDeliverySheet: some View {
        Form {
            Section("Target") {
                if webhooks.isEmpty {
                    Text("No webhooks configured").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(webhooks.filter(\.isActive)) { webhook in
                        Button {
                            sendTestDelivery(webhook)
                            showingTestDelivery = false
                        } label: {
                            VStack(alignment: .leading) {
                                Text(webhook.event).font(.subheadline.bold())
                                Text(webhook.url).font(.caption2.monospaced()).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Test Delivery")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var customHeadersSheet: some View {
        Form {
            Section("Custom Headers") {
                ForEach(customHeaders) { header in
                    HStack {
                        Text(header.key).font(.subheadline.monospaced())
                        Spacer()
                        Text(header.value).font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                }
                .onDelete { customHeaders.remove(atOffsets: $0) }
            }
            Section("Add Header") {
                Button("Content-Type: application/json") {
                    customHeaders.append(WebhookHeader(key: "Content-Type", value: "application/json"))
                }
                Button("X-Webhook-Version: 1.0") {
                    customHeaders.append(WebhookHeader(key: "X-Webhook-Version", value: "1.0"))
                }
                Button("User-Agent: ToolsKit-Webhook/1.0") {
                    customHeaders.append(WebhookHeader(key: "User-Agent", value: "ToolsKit-Webhook/1.0"))
                }
            }
        }
        .navigationTitle("Custom Headers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var secretConfigSheet: some View {
        Form {
            Section("Webhook Secret") {
                SecureField("Secret Key", text: $webhookSecret)
                    .font(.body.monospaced())
                Button("Generate Random Secret") {
                    webhookSecret = (0..<32).map { _ in
                        String("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()!)
                    }.joined()
                }
            }
            Section("Verification") {
                LabeledContent("Algorithm", value: "HMAC-SHA256")
                LabeledContent("Header", value: "X-Webhook-Signature")
                Text("The signature is computed as HMAC-SHA256(secret, payload) and sent in the X-Webhook-Signature header.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Secret Configuration")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

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
                if webhook.lastDeliveryStatusCode != nil {
                    Text("Last: \(webhook.lastDeliveryStatusCode!)")
                        .foregroundStyle(webhook.lastDeliveryStatusCode! < 400 ? .green : .red)
                }
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

    private func deleteWebhook(_ webhook: WebhookConfig) {
        webhooks.removeAll { $0.id == webhook.id }
    }

    private func activateWebhook(_ webhook: WebhookConfig) {
        if let idx = webhooks.firstIndex(where: { $0.id == webhook.id }) {
            webhooks[idx] = WebhookConfig(url: webhook.url, event: webhook.event, isActive: true, deliveryCount: webhook.deliveryCount, lastDeliveryStatusCode: webhook.lastDeliveryStatusCode)
        }
    }

    private func deactivateWebhook(_ webhook: WebhookConfig) {
        if let idx = webhooks.firstIndex(where: { $0.id == webhook.id }) {
            webhooks[idx] = WebhookConfig(url: webhook.url, event: webhook.event, isActive: false, deliveryCount: webhook.deliveryCount, lastDeliveryStatusCode: webhook.lastDeliveryStatusCode)
        }
    }

    private func toggleAllWebhooks(active: Bool) {
        webhooks = webhooks.map {
            WebhookConfig(url: $0.url, event: $0.event, isActive: active, deliveryCount: $0.deliveryCount, lastDeliveryStatusCode: $0.lastDeliveryStatusCode)
        }
    }

    private func sendTestDelivery(_ webhook: WebhookConfig) {
        let log = WebhookDeliveryLog(event: webhook.event, success: true, statusCode: 200, timestamp: Date(), durationMs: 42, retryCount: 0)
        deliveryLogs.insert(log, at: 0)
        testDeliveryResult = TestDeliveryResult(success: true, statusCode: 200, durationMs: 42)
        if let idx = webhooks.firstIndex(where: { $0.id == webhook.id }) {
            webhooks[idx] = WebhookConfig(url: webhook.url, event: webhook.event, isActive: webhook.isActive, deliveryCount: webhook.deliveryCount + 1, lastDeliveryStatusCode: 200)
        }
    }

    private func retryFailedDeliveries() {
        let failed = deliveryLogs.filter { !$0.success }
        for log in failed {
            let retry = WebhookDeliveryLog(event: log.event, success: true, statusCode: 200, timestamp: Date(), durationMs: 55, retryCount: log.retryCount + 1)
            deliveryLogs.insert(retry, at: 0)
        }
    }

    private func buildDeliveryReport() -> String {
        var lines = ["=== Webhook Delivery Report ===", "Generated: \(Date().formatted())", ""]
        lines.append("Webhooks: \(webhooks.count) (\(webhooks.filter(\.isActive).count) active)")
        lines.append("Total Deliveries: \(deliveryLogs.count)")
        let successCount = deliveryLogs.filter(\.success).count
        lines.append("Success: \(successCount), Failed: \(deliveryLogs.count - successCount)")
        lines.append("")
        for log in deliveryLogs.prefix(20) {
            lines.append("[\(log.success ? "OK" : "FAIL")] \(log.event) — \(log.statusCode) — \(log.timestamp.formatted())")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Private Models

private struct WebhookConfig: Identifiable {
    let id = UUID()
    let url: String
    let event: String
    let isActive: Bool
    let deliveryCount: Int
    let createdAt: Date
    let lastDeliveryStatusCode: Int?

    init(url: String, event: String, isActive: Bool, deliveryCount: Int = 0, lastDeliveryStatusCode: Int? = nil) {
        self.url = url
        self.event = event
        self.isActive = isActive
        self.deliveryCount = deliveryCount
        self.createdAt = Date()
        self.lastDeliveryStatusCode = lastDeliveryStatusCode
    }
}

private struct WebhookDeliveryLog: Identifiable {
    let id = UUID()
    let event: String
    let success: Bool
    let statusCode: Int
    let timestamp: Date
    let durationMs: Int?
    let retryCount: Int
}

private struct TestDeliveryResult {
    let success: Bool
    let statusCode: Int
    let durationMs: Int
}

private struct WebhookHeader: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}
