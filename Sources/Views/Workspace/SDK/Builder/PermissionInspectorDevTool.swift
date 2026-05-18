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

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Permission Inspector",
                description: "Monitor and request authorization for system services like Camera, Location, and Notifications.",
                icon: "hand.raised.fill"
            )
            .padding()

            List {
                ForEach(viewModel.permissions) { perm in
                    HStack {
                        Image(systemName: perm.icon)
                            .foregroundStyle(.accent)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text(perm.name).font(.subheadline.bold())
                            Text(perm.description).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusBadge(text: perm.status, color: statusColor(perm.status))
                    }
                }
            }
        }
        .onAppear { viewModel.load() }
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

struct PermissionItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let status: String
}

class PermissionInspectorViewModel: ObservableObject {
    @Published var permissions: [PermissionItem] = []

    func load() {
        permissions = [
            PermissionItem(name: "Camera", icon: "camera.fill", description: "Access for scanning and video", status: "Authorized"),
            PermissionItem(name: "Location", icon: "location.fill", description: "GPS and navigation", status: "Denied"),
            PermissionItem(name: "Notifications", icon: "bell.fill", description: "Push alerts and updates", status: "Authorized"),
            PermissionItem(name: "Microphone", icon: "mic.fill", description: "Audio recording", status: "Not Determined")
        ]
    }
}
