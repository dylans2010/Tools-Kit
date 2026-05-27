import SwiftUI

struct SDKSecurityAuditView: View {
    @StateObject private var auditLogger = SDKAuditLogger.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var isScanning = false

    var body: some View {
        List {
            controlsSection
            logsSection
        }
        .navigationTitle("Security Audit")
    }

    private var filteredEvents: [SDKAuditLogger.Event] {
        let currentProjectID = projectManager.currentProject?.id
        return auditLogger.events.filter { event in
            guard let id = currentProjectID else { return true }
            return event.projectID == id || event.projectID == nil
        }
    }

    private var controlsSection: some View {
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
    }

    private var logsSection: some View {
        Section("Audit Logs") {
            if filteredEvents.isEmpty {
                ContentUnavailableView("No Events Found", systemImage: "checkmark.shield", description: Text("No security or privacy events have been recorded yet."))
            } else {
                ForEach(filteredEvents) { event in
                    AuditEventRow(event: event, colorProvider: color(for:))
                }
            }
        }
    }

    private func refreshAudit() {
        isScanning = true

        auditLogger.log(
            eventType: .security,
            projectID: projectManager.currentProject?.id,
            scope: "security.audit",
            message: "Manual security audit performed by user."
        )

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

private struct AuditEventRow: View {
    let event: SDKAuditLogger.Event
    let colorProvider: (SDKAuditLogger.Event.EventType) -> Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Text(event.message)
                .font(.subheadline.bold())

            if !event.scope.isEmpty {
                Text("Scope: \(event.scope)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !event.metadata.isEmpty {
                metadataDisclosure
            }
        }
        .padding(.vertical, 4)
    }

    private var header: some View {
        HStack {
            Text(event.eventType.rawValue.uppercased())
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(colorProvider(event.eventType).opacity(0.2), in: Capsule())
                .foregroundStyle(colorProvider(event.eventType))

            Spacer()

            Text(event.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var metadataDisclosure: some View {
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
