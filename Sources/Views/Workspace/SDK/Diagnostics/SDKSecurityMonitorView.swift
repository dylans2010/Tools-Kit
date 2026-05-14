

import SwiftUI

struct SDKSecurityMonitorView: View {
    @StateObject private var scopeManager = SDKScopeManager.shared
    @StateObject private var securityManager = SDKSecurityManager.shared
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @State private var selectedFilter: SecurityFilter = .all
    @State private var sensitiveOps: [SDKSecurityManager.SensitiveOperation] = []

    enum SecurityFilter: String, CaseIterable {
        case all = "All", granted = "Granted", blocked = "Blocked"
    }

    private var filteredLogs: [SDKScopeManager.ScopeAuditEntry] {
        switch selectedFilter {
        case .all: return scopeManager.scopeAuditLog
        case .granted: return scopeManager.scopeAuditLog.filter { $0.granted }
        case .blocked: return scopeManager.scopeAuditLog.filter { !$0.granted }
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Log Filter", selection: $selectedFilter) {
                    ForEach(SecurityFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                if filteredLogs.isEmpty {
                    Text("No access events recorded").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(filteredLogs) { entry in
                        AccessEventRow(entry: entry)
                    }
                }
            } header: {
                Label("Access History", systemImage: "clock.badge.checkmark")
            }

            Section {
                LabeledContent("Kernel Policy", value: runtime.isNoSandboxModeEnabled ? "Unrestricted" : "Sandboxed")
                    .foregroundStyle(runtime.isNoSandboxModeEnabled ? Color.red : Color.green).bold()

                LabeledContent("Active Scopes", value: "\(scopeManager.authorizedScopes.count)")

                let blockedCount = scopeManager.scopeAuditLog.filter { !$0.granted }.count
                LabeledContent("Blocked Attempts", value: "\(blockedCount)")
                    .foregroundStyle(blockedCount > 0 ? Color.orange : Color.secondary)

                let grantedCount = scopeManager.scopeAuditLog.filter { $0.granted }.count
                LabeledContent("Granted Access", value: "\(grantedCount)")
            } header: {
                Label("Security Summary", systemImage: "shield.checkered")
            }

            Section {
                if scopeManager.authorizedScopes.isEmpty {
                    Text("No scope restrictions defined").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(scopeManager.authorizedScopes).sorted(), id: \.self) { scope in
                        Label {
                            Text(scope).font(.caption.monospaced())
                        } icon: {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                    }
                }
            } header: {
                Label("Authorized Scopes", systemImage: "lock.open.fill")
            }

            Section {
                if sensitiveOps.isEmpty {
                    Text("No sensitive operations detected").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(sensitiveOps) { op in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(op.scope).font(.caption.monospaced().bold())
                                Spacer()
                                Text(op.timestamp, style: .time).font(.caption2).foregroundStyle(.secondary)
                            }
                            Text(op.reason).font(.caption2).foregroundStyle(.red)
                        }
                    }
                }
            } header: {
                Label("Critical Alerts (Live)", systemImage: "bolt.shield.fill")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Security Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            sensitiveOps = securityManager.sensitiveOperations
        }
        .task {
            // Stream-like updates (poll for this implementation)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    sensitiveOps = securityManager.sensitiveOperations
                }
            }
        }
    }
}

// MARK: - Private Subviews

private struct AccessEventRow: View {
    let entry: SDKScopeManager.ScopeAuditEntry
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.granted ? "checkmark.shield.fill" : "lock.shield.fill")
                .foregroundStyle(entry.granted ? Color.green : Color.red)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.scope).font(.caption.monospaced().bold())
                Text("\(entry.operation.rawValue.capitalized) — \(entry.reason ?? "Authorized")")
                    .font(.caption2).foregroundStyle(.secondary)
                Text(entry.timestamp, style: .time).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
