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
        List {
            Section {
                ForEach(rateLimitLines, id: \.self) { line in
                    Text(line).font(.system(.caption, design: .monospaced))
                }
                Button("Reset Counters (Dev)") {
                    Task {
                        await SDKRateLimiter.shared.resetAllCounters()
                        rateUsage = await SDKRateLimiter.shared.currentUsage()
                    }
                }
            } header: {
                Text("Rate Limit Monitor")
            }

            Section {
                ForEach(policyEngine.availableScopes(), id: \.name) { scope in
                    HStack {
                        Text(scope.name)
                            .font(.caption)
                        Spacer()
                        Text(scope.riskLevel.rawValue.capitalized)
                            .font(.caption2.bold())
                            .foregroundStyle(scope.riskLevel == .critical || scope.riskLevel == .high ? .red : .secondary)
                    }
                }
            } header: {
                Text("Scope Inspector")
            }

            Section {
                ForEach(privacyManager.exposureLogs.prefix(20)) { log in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(log.scope).font(.caption.bold())
                        Text("Redacted: \(log.redactedFields.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Privacy Inspector")
            }

            Section {
                Picker("Scope", selection: $rawScope) {
                    ForEach(SDKScope.allCases, id: \.self) { scope in
                        Text(String(describing: scope)).tag(scope)
                    }
                }
                Button("Run sdk.fetchData") {
                    Task {
                        let data = (try? await ToolsKitSDK.shared.fetchData(scope: rawScope)) ?? []
                        rawData = data.prefix(10).map { "\($0.title) [\($0.scope)]" }.joined(separator: "\n")
                    }
                }
                if !rawData.isEmpty {
                    Text(rawData).font(.system(.caption, design: .monospaced))
                }
            } header: {
                Text("Raw Data Explorer")
            }

            Section {
                TextField("URL", text: $endpointURL)
                    .textInputAutocapitalization(.never)
                Button("Test Endpoint") {
                    Task {
                        do {
                            let data = try await ToolsKitSDK.shared.externalFetch(url: endpointURL)
                            endpointResult = String(data: data.prefix(512), encoding: .utf8) ?? "<binary>"
                        } catch {
                            endpointResult = error.localizedDescription
                        }
                    }
                }
                if !endpointResult.isEmpty {
                    Text(endpointResult).font(.system(.caption, design: .monospaced))
                }
            } header: {
                Text("Endpoint Tester")
            }

            Section {
                ForEach(SDKExecutionEngine.shared.executionHistory.prefix(20)) { entry in
                    HStack {
                        Text(entry.actionLabel)
                        Spacer()
                        Text(entry.success ? "OK" : "FAIL")
                            .foregroundStyle(entry.success ? .green : .red)
                    }
                    .font(.caption)
                }
            } header: {
                Text("Execution Trace Viewer")
            }

            Section {
                Picker("Type", selection: $selectedEventType) {
                    Text("All").tag(Optional<SDKAuditLogger.Event.EventType>.none)
                    ForEach(SDKAuditLogger.Event.EventType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(Optional(type))
                    }
                }
                ForEach(filteredAuditLogs.prefix(50)) { event in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(event.message).font(.caption)
                        Text("\(event.eventType.rawValue) · \(event.timestamp.formatted(date: .omitted, time: .standard))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Audit Logs Panel")
            }

            Section {
                ForEach(securityManager.sensitiveOperations.prefix(20)) { op in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(op.scope).font(.caption.bold())
                        Text(op.reason).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Sensitive Operations")
            }
        }
        .navigationTitle("SDK Internal")
        .task {
            rateUsage = await SDKRateLimiter.shared.currentUsage()
        }
    }

    private var filteredAuditLogs: [SDKAuditLogger.Event] {
        auditLogger.query(projectID: projectManager.currentProject?.id, eventType: selectedEventType)
    }

    private var rateLimitLines: [String] {
        if rateUsage.isEmpty { return ["No active usage"] }
        return rateUsage.map { "\($0.key) req:\($0.requestsInWindow)/\($0.requestsPerMinute) fetch:\($0.fetchUnitsInWindow) exec:\($0.executionsInWindow)" }
    }
}

private extension SDKExecutionEngine.ExecutionRecord {
    var actionLabel: String {
        String(describing: action)
    }
}
