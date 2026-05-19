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
        List {
            ForEach($viewModel.permissions) { $perm in
                HStack {
                    Image(systemName: perm.icon)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 30)
                    VStack(alignment: .leading) {
                        Text(perm.name).font(.subheadline.bold())
                        Text(perm.description).font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(perm.status)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(statusColor(perm.status), in: RoundedRectangle(cornerRadius: 4))
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

struct PermissionInspectorItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let status: String
}

class PermissionInspectorViewModel: ObservableObject {
    @Published var permissions: [PermissionInspectorItem] = []

    func load() {
        permissions = [
            PermissionInspectorItem(name: "Camera", icon: "camera.fill", description: "Access for scanning and video", status: "Authorized"),
            PermissionInspectorItem(name: "Location", icon: "location.fill", description: "GPS and navigation", status: "Denied"),
            PermissionInspectorItem(name: "Notifications", icon: "bell.fill", description: "Push alerts and updates", status: "Authorized"),
            PermissionInspectorItem(name: "Microphone", icon: "mic.fill", description: "Audio recording", status: "Not Determined")
        ]
    }
}

#Preview {
    PermissionInspectorView()
}
