import SwiftUI

struct SDKSecurityMonitorView: View {
    @StateObject private var scopeManager = SDKScopeManager.shared
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @State private var selectedFilter: SecurityFilter = .all

    enum SecurityFilter: String, CaseIterable {
        case all = "All"
        case granted = "Granted"
        case blocked = "Blocked"
    }

    var body: some View {
        List {
            Section("Access Logs") {
                if filteredLogs.isEmpty {
                    Text("No access logs recorded yet").foregroundStyle(.secondary)
                } else {
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(SecurityFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)

                    ForEach(filteredLogs) { entry in
                        HStack(alignment: .top) {
                            Image(systemName: entry.granted ? "checkmark.shield.fill" : "lock.shield.fill")
                                .foregroundStyle(entry.granted ? .green : .red)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.scope).font(.subheadline).bold()
                                Text("\(entry.operation.rawValue.capitalized) — \(entry.reason ?? "Authorized")")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(entry.timestamp, style: .time)
                                    .font(.system(size: 10, design: .monospaced))
                            }
                        }
                    }
                }
            }

            Section("Security Summary") {
                InfoRow(label: "Enforcement Mode", value: runtime.isNoSandboxModeEnabled ? "Unrestricted (NoSandbox)" : "Strict (Sandbox)")
                InfoRow(label: "Active Scopes", value: "\(scopeManager.authorizedScopes.count)")

                let blockedCount = scopeManager.scopeAuditLog.filter { !$0.granted }.count
                InfoRow(label: "Blocked Attempts", value: "\(blockedCount)")

                let grantedCount = scopeManager.scopeAuditLog.filter { $0.granted }.count
                InfoRow(label: "Granted Access", value: "\(grantedCount)")
            }

            Section("Authorized Scopes") {
                if scopeManager.authorizedScopes.isEmpty {
                    Text("All scopes implicitly authorized (no restrictions set)")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(scopeManager.authorizedScopes).sorted(), id: \.self) { scope in
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text(scope).font(.system(.caption, design: .monospaced))
                        }
                    }
                }
            }
        }
        .navigationTitle("Security Monitor")
    }

    private var filteredLogs: [SDKScopeManager.ScopeAuditEntry] {
        switch selectedFilter {
        case .all: return scopeManager.scopeAuditLog
        case .granted: return scopeManager.scopeAuditLog.filter { $0.granted }
        case .blocked: return scopeManager.scopeAuditLog.filter { !$0.granted }
        }
    }
}
