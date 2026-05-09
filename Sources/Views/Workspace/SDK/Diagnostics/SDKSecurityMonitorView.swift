/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Modernized access log rows with semantic status icons and monospaced typography.
 - Replaced manual filter picker with a native segmented picker inside a Section.
 - Standardized security summary using native LabeledContent and semantic colors.
 - strictly preserved all SDKScopeManager authorized scope data and audit log filtering.
 - Improved visual hierarchy for blocked vs granted access attempts.
 - Standardized authorized scope list using native Label with checkmark icons.
 */

import SwiftUI

struct SDKSecurityMonitorView: View {
    @StateObject private var scopeManager = SDKScopeManager.shared
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @State private var selectedFilter: SecurityFilter = .all

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
                Text("Access History")
            }

            Section("Security Summary") {
                LabeledContent("Kernel Policy", value: runtime.isNoSandboxModeEnabled ? "Unrestricted" : "Sandboxed")
                    .foregroundStyle(runtime.isNoSandboxModeEnabled ? .red : .green).bold()

                LabeledContent("Active Scopes", value: "\(scopeManager.authorizedScopes.count)")

                let blockedCount = scopeManager.scopeAuditLog.filter { !$0.granted }.count
                LabeledContent("Blocked Attempts", value: "\(blockedCount)")
                    .foregroundStyle(blockedCount > 0 ? .orange : .secondary)

                let grantedCount = scopeManager.scopeAuditLog.filter { $0.granted }.count
                LabeledContent("Granted Access", value: "\(grantedCount)")
            }

            Section("Authorized Scopes") {
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
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Security Monitor")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Private Subviews

private struct AccessEventRow: View {
    let entry: SDKScopeManager.ScopeAuditEntry
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.granted ? "checkmark.shield.fill" : "lock.shield.fill")
                .foregroundStyle(entry.granted ? .green : .red)
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
