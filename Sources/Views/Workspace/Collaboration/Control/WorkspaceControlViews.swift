import SwiftUI

struct WorkspaceCommandCenterView: View {
    @StateObject private var controlCenter = WorkspaceControlCenter.shared
    @State private var auditLogs: [String] = []

    var body: some View {
        List {
            Section("System Status") {
                HStack {
                    Label("Total Spaces", systemImage: "folder")
                    Spacer()
                    Text("\(CollaborationManager.shared.spaces.count)")
                }

                Button("Run Global Audit") {
                    auditLogs = controlCenter.performGlobalAudit()
                }
            }

            Section("Audit Logs") {
                if auditLogs.isEmpty {
                    Text("No issues found.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(auditLogs, id: \.self) { log in
                        Label(log, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                    }
                }
            }

            Section("Bulk Operations") {
                Button("Bulk Permission Edit") {
                    // Navigate to bulk edit UI
                }
            }
        }
        .navigationTitle("Command Center")
    }
}

struct DependencyInspectorView: View {
    let objectID: UUID
    @StateObject private var inspector = DependencyInspector.shared
    @State private var impactReport = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Dependency Inspector")
                .font(.title2)
                .bold()

            Text("Object ID: \(objectID.uuidString)")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading) {
                Text("Impact Analysis")
                    .font(.headline)

                Text(impactReport.isEmpty ? "Run analysis to see impact." : impactReport)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }

            Button("Analyze Impact") {
                impactReport = inspector.analyzeDeletionImpact(objectID: objectID)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}
