import SwiftUI

struct PermissionInspectorDevTool: DevTool {
    let id = "permission-inspector"
    let name = "Permission Inspector"
    let category = DevToolCategory.security
    let icon = "hand.raised.fill"
    let description = "Check and request app permissions"

    func render() -> some View {
        PermissionInspectorView()
    }
}

struct PermissionInspectorView: View {
    @StateObject private var viewModel = PermissionInspectorViewModel()
    @State private var showingAuditSheet = false

    var body: some View {
        List {
            Section("Status Overview") {
                HStack(spacing: 20) {
                    PermissionStat(label: "Authorized", count: viewModel.authorizedCount, color: .green)
                    PermissionStat(label: "Denied", count: viewModel.deniedCount, color: .red)
                    PermissionStat(label: "Pending", count: viewModel.pendingCount, color: .orange)
                }
                .padding(.vertical, 8)
            }

            Section("System Permissions") {
                ForEach($viewModel.permissions) { $perm in
                    NavigationLink {
                        PermissionDetailView(item: perm)
                    } label: {
                        HStack {
                            Image(systemName: perm.icon)
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(perm.name).font(.subheadline.bold())
                                Text(perm.status)
                                    .font(.caption2)
                                    .foregroundStyle(statusColor(perm.status))
                            }

                            Spacer()

                            if perm.status == "Authorized" {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }

            Section("Actions") {
                Button {
                    showingAuditSheet = true
                } label: {
                    Label("Run Security Audit", systemImage: "shield.lefthalf.filled")
                }

                Button {
                    viewModel.refreshAll()
                } label: {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }

                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    Label("Open System Settings", systemImage: "gear")
                }
            }
        }
        .navigationTitle("Permissions")
        .onAppear { viewModel.load() }
        .sheet(isPresented: $showingAuditSheet) {
            PermissionAuditView(viewModel: viewModel)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "authorized": return .green
        case "denied": return .red
        case "not determined": return .secondary
        default: return .orange
        }
    }
}

struct PermissionInspectorItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let status: String
}

class PermissionInspectorViewModel: ObservableObject {
    @Published var permissions: [PermissionInspectorItem] = []

    var authorizedCount: Int { permissions.filter { $0.status == "Authorized" }.count }
    var deniedCount: Int { permissions.filter { $0.status == "Denied" }.count }
    var pendingCount: Int { permissions.filter { $0.status == "Not Determined" }.count }

    func load() {
        permissions = [
            PermissionInspectorItem(name: "Camera", icon: "camera.fill", description: "Used for SDK scanning and identity verification.", status: "Authorized"),
            PermissionInspectorItem(name: "Location", icon: "location.fill", description: "Required for region-based policy enforcement.", status: "Denied"),
            PermissionInspectorItem(name: "Notifications", icon: "bell.fill", description: "Used for background task completion alerts.", status: "Authorized"),
            PermissionInspectorItem(name: "Microphone", icon: "mic.fill", description: "Voice commands and audio analysis.", status: "Not Determined"),
            PermissionInspectorItem(name: "Bluetooth", icon: "wave.3.right", description: "Local device discovery for connectors.", status: "Authorized"),
            PermissionInspectorItem(name: "Photo Library", icon: "photo.on.rectangle", description: "SDK media asset management.", status: "Not Determined"),
            PermissionInspectorItem(name: "Contacts", icon: "person.2.fill", description: "Connector sync for CRM modules.", status: "Denied")
        ]
    }

    func refreshAll() {
        load() // Simulation
    }
}

struct PermissionStat: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct PermissionDetailView: View {
    let item: PermissionInspectorItem

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Permission", value: item.name)
                LabeledContent("Current Status", value: item.status)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description").font(.caption).foregroundStyle(.secondary)
                    Text(item.description).font(.subheadline)
                }
            }

            Section("SDK Impact") {
                Text("This permission is mapped to the **SDKCore** module. If denied, certain features like automated sync may be disabled.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(item.name)
    }
}

struct PermissionAuditView: View {
    @ObservedObject var viewModel: PermissionInspectorViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Risk Analysis") {
                    AuditRow(title: "Critical Scopes", count: 2, color: .red)
                    AuditRow(title: "Privacy Sensitive", count: 4, color: .orange)
                    AuditRow(title: "Background Usage", count: 1, color: .blue)
                }

                Section("Recommendations") {
                    Text("• Grant Location access to enable region-locking.")
                    Text("• Review Contacts access if CRM sync is not required.")
                }
            }
            .navigationTitle("Security Audit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}

struct AuditRow: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(count)")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(color, in: Capsule())
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    PermissionInspectorView()
}
