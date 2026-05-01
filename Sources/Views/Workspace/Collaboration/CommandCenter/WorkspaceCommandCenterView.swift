import SwiftUI

struct WorkspaceCommandCenterView: View {
    @StateObject private var controller = CommandCenterController.shared
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Section", selection: $selectedTab) {
                    Text("Merges").tag(0)
                    Text("Permissions").tag(1)
                    Text("Audit Logs").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    MergeDashboard()
                } else if selectedTab == 1 {
                    PermissionControl()
                } else {
                    GlobalAuditFeed()
                }
            }
            .navigationTitle("Command Center")
        }
    }
}

struct MergeDashboard: View {
    let merges = CommandCenterController.shared.getAllPendingMerges()

    var body: some View {
        List(merges) { pr in
            VStack(alignment: .leading) {
                Text(pr.title).bold()
                Text("Space: \(pr.spaceID.uuidString.prefix(8))").font(.caption).foregroundColor(.secondary)
            }
        }
        .overlay {
            if merges.isEmpty {
                ContentUnavailableView("No Pending Merges", systemImage: "arrow.merge", description: Text("All spaces are up to date."))
            }
        }
    }
}

struct PermissionControl: View {
    var body: some View {
        List {
            Text("Bulk Permission Management")
                .font(.headline)
            // Implementation for multi-select spaces and role assignment
        }
    }
}

struct GlobalAuditFeed: View {
    let logs = CommandCenterController.shared.getGlobalAuditLogs()

    var body: some View {
        List(logs) { log in
            HStack {
                VStack(alignment: .leading) {
                    Text(log.action)
                    Text(log.userName).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(log.timestamp, style: .time).font(.caption2)
            }
        }
    }
}
