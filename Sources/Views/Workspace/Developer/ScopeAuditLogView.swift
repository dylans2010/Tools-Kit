import SwiftUI

struct ScopeAuditLogView: View {
    @ObservedObject var scopeService = DeveloperScopeService.shared

    var body: some View {
        List {
            Section("History of Permission Changes") {
                if scopeService.auditLog.isEmpty {
                    Text("No scope audit events found.").foregroundStyle(.secondary)
                } else {
                    ForEach(scopeService.auditLog) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.eventType).font(.subheadline.bold())
                                Spacer()
                                Text(event.timestamp.formatted()).font(.caption2).foregroundStyle(.tertiary)
                            }
                            Text("scope:\(event.scopeIdentifier)").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Scope Audit Log")
    }
}
