import SwiftUI

struct WorkspaceCommandCenterView: View {
    @StateObject private var service = WorkspaceCommandCenterService()

    var body: some View {
        List {
            Button("Run Permission + Merge Audit") { service.runAudit() }
            Section("Audit Log") {
                ForEach(service.auditEvents) { event in
                    VStack(alignment: .leading) {
                        Text(event.message)
                        Text(event.timestamp, style: .time).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Command Center")
    }
}
