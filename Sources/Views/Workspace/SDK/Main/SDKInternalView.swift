/*
 REDESIGN SUMMARY:
 - Transitioned to native Form structure for cleaner system debugging.
 - Standardized on monospaced typography for all technical and raw data outputs.
 - Replaced manual HStack layouts with LabeledContent and native Pickers.
 - Standardized risk level colors using semantic .red and .secondary.
 - strictly preserved all AuditLogger, PrivacyManager, and PolicyEngine logic.
 - Replaced manual trace lists with standard List rows.
 */

import SwiftUI

struct SDKInternalView: View {
    @StateObject private var auditLogger = SDKAuditLogger.shared
    @StateObject private var privacyManager = SDKPrivacyManager.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var policyEngine = SDKPolicyEngine.shared
    @StateObject private var securityManager = SDKSecurityManager.shared

    @State private var selectedEventType: SDKAuditLogger.Event.EventType?
    @State private var endpointURL = "https://api.github.com"
    @State private var endpointResult = ""
    @State private var rawScope: SDKScope = .all
    @State private var rawData: String = ""
    @State private var rateUsage: [SDKRateLimiter.UsageSnapshot] = []

    var body: some View {
        Form {
            Section("Rate Limit Monitor") {
                ForEach(rateLimitLines, id: \.self) { line in
                    Text(line).font(.system(.caption, design: .monospaced))
                }
                Button("Reset Counters", role: .destructive) {
                    Task {
                        await SDKRateLimiter.shared.resetAllCounters()
                        rateUsage = await SDKRateLimiter.shared.currentUsage()
                    }
                }
            }

            Section("Scope Inspector") {
                ForEach(policyEngine.availableScopes(), id: \.name) { scope in
                    LabeledContent(scope.name) {
                        Text(scope.riskLevel.rawValue.capitalized)
                            .font(.caption2.bold())
                            .foregroundStyle(scope.riskLevel == .critical || scope.riskLevel == .high ? Color.red : Color.secondary)
                    }
                }
            }

            Section("Privacy Logs") {
                ForEach(privacyManager.exposureLogs.prefix(15)) { log in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.scope).font(.caption.bold())
                        Text("Redacted: \(log.redactedFields.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Raw Data Explorer") {
                Picker("Scope", selection: $rawScope) {
                    ForEach(SDKScope.allCases, id: \.self) { scope in
                        Text(String(describing: scope)).tag(scope)
                    }
                }
                Button("Fetch Data") {
                    Task {
                        let data = (try? await ToolsKitSDK.shared.fetchData(scope: rawScope)) ?? []
                        rawData = data.prefix(10).map { "\($0.title) [\($0.scope)]" }.joined(separator: "\n")
                    }
                }
                if !rawData.isEmpty {
                    Text(rawData).font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Endpoint Tester") {
                TextField("URL", text: $endpointURL)
                    .textInputAutocapitalization(.never)
                Button("Execute Request") {
                    Task {
                        do {
                            let data = try await ToolsKitSDK.shared.externalFetch(url: endpointURL)
                            endpointResult = String(data: data.prefix(512), encoding: .utf8) ?? "<binary content>"
                        } catch {
                            endpointResult = error.localizedDescription
                        }
                    }
                }
                if !endpointResult.isEmpty {
                    Text(endpointResult).font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Execution Traces") {
                ForEach(SDKExecutionEngine.shared.executionHistory.prefix(15)) { entry in
                    LabeledContent(entry.actionLabel) {
                        Text(entry.success ? "OK" : "FAIL")
                            .font(.caption.bold())
                            .foregroundStyle(entry.success ? Color.green : Color.red)
                    }
                }
            }

            Section("Audit Logs") {
                Picker("Filter Type", selection: $selectedEventType) {
                    Text("All").tag(Optional<SDKAuditLogger.Event.EventType>.none)
                    ForEach(SDKAuditLogger.Event.EventType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(Optional(type))
                    }
                }
                ForEach(filteredAuditLogs.prefix(30)) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.message).font(.caption)
                        Text("\(event.eventType.rawValue) · \(event.timestamp.formatted(date: .omitted, time: .standard))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Internal")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            rateUsage = await SDKRateLimiter.shared.currentUsage()
        }
    }

    private var filteredAuditLogs: [SDKAuditLogger.Event] {
        auditLogger.query(projectID: projectManager.currentProject?.id, eventType: selectedEventType)
    }

    private var rateLimitLines: [String] {
        if rateUsage.isEmpty { return ["No active usage"] }
        return rateUsage.map { "\($0.key) req:\($0.requestsInWindow)/\($0.requestsPerMinute)" }
    }
}

private extension SDKExecutionEngine.ExecutionRecord {
    var actionLabel: String {
        String(describing: action)
    }
}
