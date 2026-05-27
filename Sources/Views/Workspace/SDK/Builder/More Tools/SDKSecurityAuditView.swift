import SwiftUI

struct SDKSecurityAuditView: View {
    @StateObject private var auditLogger = SDKAuditLogger.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var isScanning = false

    var body: some View {
        List {
            Section("Security Controls") {
                Button(action: refreshAudit) {
                    HStack {
                        Label("Refresh Audit Logs", systemImage: "arrow.clockwise.shield")
                        Spacer()
                        if isScanning { ProgressView() }
                    }
                }
                .disabled(isScanning)
            }

            Section("Audit Logs") {
                let currentProjectID = projectManager.currentProject?.id
                let events = auditLogger.events.filter { event in
                    if let id = currentProjectID {
                        return event.projectID == id || event.projectID == nil
                    }
                    return true
                }

                if events.isEmpty {
                    ContentUnavailableView("No Events Found", systemImage: "checkmark.shield", description: Text("No security or privacy events have been recorded yet."))
                } else {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(event.eventType.rawValue.uppercased())
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(color(for: event.eventType).opacity(0.2), in: Capsule())
                                    .foregroundStyle(color(for: event.eventType))

                                Spacer()

                                Text(event.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Text(event.message)
                                .font(.subheadline.bold())

                            if !event.scope.isEmpty {
                                Text("Scope: \(event.scope)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if !event.metadata.isEmpty {
                                DisclosureGroup {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(Array(event.metadata.keys).sorted(), id: \.self) { key in
                                            HStack {
                                                Text(key).bold()
                                                Spacer()
                                                Text(event.metadata[key] ?? "")
                                            }
                                            .font(.system(size: 10, design: .monospaced))
                                        }
                                    }
                                    .padding(.top, 4)
                                } label: {
                                    Text("Metadata").font(.caption2).foregroundStyle(.accent)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Security Audit")
    }

    private func refreshAudit() {
        isScanning = true

        // Record the audit event
        auditLogger.log(
            eventType: .security,
            projectID: projectManager.currentProject?.id,
            scope: "security.audit",
            message: "Manual security audit performed by user."
        )

        // Immediate completion as we are just refreshing existing logs
        isScanning = false
    }

    private func color(for eventType: SDKAuditLogger.Event.EventType) -> Color {
        switch eventType {
        case .security: return .red
        case .privacy: return .orange
        case .dataAccess: return .blue
        case .scopeUsage: return .purple
        case .externalAPICall: return .green
        case .execution: return .gray
        }
    }
}
