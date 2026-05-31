import SwiftUI

struct ScopeAuditLogView: View {
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    var body: some View {
        List {
            Section("Security Audit Trail") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled").foregroundStyle(.secondary)
                        Text("Permission Lifecycle").font(.subheadline.bold())
                    }
                    Text("Historical record of all scope grants, revocations, and requests across your fleet of applications.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Recent Events") {
                if scopeService.auditLog.isEmpty {
                    EmptyStateView(icon: "list.bullet.indent", title: "No Audit Events", message: "Detailed logs of permission changes will appear here as they occur.")
                } else {
                    ForEach(scopeService.auditLog.sorted(by: { $0.timestamp > $1.timestamp })) { event in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(event.eventType.uppercased())
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(eventColor(event.eventType).opacity(0.1))
                                    .foregroundStyle(eventColor(event.eventType))
                                    .clipShape(Capsule())

                                Spacer()

                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 8))
                                    .foregroundStyle(.tertiary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.scopeIdentifier).font(.subheadline.monospaced()).bold()
                                if let app = appService.apps.first(where: { $0.id == event.appID }) {
                                    Text("Application: \(app.name)").font(.system(size: 9)).foregroundStyle(.secondary)
                                } else {
                                    Text("Account-level permission").font(.system(size: 9)).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Scope Audit")
    }

    private func eventColor(_ type: String) -> Color {
        switch type {
        case "Grant": return .green
        case "Revoke": return .red
        case "Request": return .blue
        default: return .secondary
        }
    }
}
