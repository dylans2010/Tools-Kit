

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
            Section {
                ForEach(rateLimitLines, id: \.self) { line in
                    Text(line).font(.system(.caption, design: .monospaced))
                }
                Button(role: .destructive) {
                    Task {
                        await SDKRateLimiter.shared.resetAllCounters()
                        rateUsage = await SDKRateLimiter.shared.currentUsage()
                    }
                } label: {
                    Label("Reset Counters", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Label("Rate Limit Monitor", systemImage: "gauge.with.needle")
            }

            Section {
                ForEach(policyEngine.availableScopes(), id: \.name) { scope in
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundStyle(scope.riskLevel == .critical || scope.riskLevel == .high ? Color.red : Color.secondary)
                        LabeledContent(scope.name) {
                            Text(scope.riskLevel.rawValue.capitalized)
                                .font(.caption2.bold())
                                .foregroundStyle(scope.riskLevel == .critical || scope.riskLevel == .high ? Color.red : Color.secondary)
                        }
                    }
                }
            } header: {
                Label("Scope Inspector", systemImage: "lock.shield")
            }

            Section {
                ForEach(privacyManager.exposureLogs.prefix(15)) { log in
                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.scope).font(.caption.bold())
                            Text("Redacted: \(log.redactedFields.joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Label("Privacy Logs", systemImage: "eye.slash.fill")
            }

            Section {
                Picker("Scope", selection: $rawScope) {
                    ForEach(SDKScope.allCases, id: \.self) { scope in
                        Text(String(describing: scope)).tag(scope)
                    }
                }
                Button {
                    Task {
                        let data = (try? await ToolsKitSDK.shared.fetchData(scope: rawScope)) ?? []
                        rawData = data.prefix(10).map { "\($0.title) [\($0.scope)]" }.joined(separator: "\n")
                    }
                } label: {
                    Label("Fetch Data", systemImage: "arrow.down.circle")
                }
                if !rawData.isEmpty {
                    Text(rawData).font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Raw Data Explorer", systemImage: "cylinder.split.1x2")
            }

            Section {
                TextField("URL", text: $endpointURL)
                    .textInputAutocapitalization(.never)
                Button {
                    Task {
                        do {
                            let data = try await ToolsKitSDK.shared.externalFetch(url: endpointURL)
                            endpointResult = String(data: data.prefix(512), encoding: .utf8) ?? "<binary content>"
                        } catch {
                            endpointResult = error.localizedDescription
                        }
                    }
                } label: {
                    Label("Execute Request", systemImage: "play.circle.fill")
                }
                if !endpointResult.isEmpty {
                    Text(endpointResult).font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Endpoint Tester", systemImage: "network")
            }

            Section {
                ForEach(SDKExecutionEngine.shared.executionHistory.prefix(15)) { entry in
                    HStack {
                        Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(entry.success ? Color.green : Color.red)
                        LabeledContent(entry.actionLabel) {
                            Text(entry.success ? "OK" : "FAIL")
                                .font(.caption.bold())
                                .foregroundStyle(entry.success ? Color.green : Color.red)
                        }
                    }
                }
            } header: {
                Label("Execution Traces", systemImage: "waveform.path")
            }

            Section {
                Picker("Filter Type", selection: $selectedEventType) {
                    Text("All").tag(Optional<SDKAuditLogger.Event.EventType>.none)
                    ForEach(SDKAuditLogger.Event.EventType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(Optional(type))
                    }
                }
                ForEach(filteredAuditLogs.prefix(30)) { event in
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.message).font(.caption)
                            Text("\(event.eventType.rawValue) · \(event.timestamp.formatted(date: .omitted, time: .standard))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Label("Audit Logs", systemImage: "list.bullet.clipboard")
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
