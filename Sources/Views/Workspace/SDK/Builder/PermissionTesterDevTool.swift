import SwiftUI

struct PermissionTesterDevTool: DevTool {
    let id = "permission-tester"
    let name = "Permission Tester"
    let category: DevToolCategory = .diagnostics
    let icon = "lock.rectangle.stack"
    let description = "Check and request system permissions (Camera, Location, etc.)"

    func render() -> some View {
        List {
            PermissionRow(name: "Camera", icon: "camera")
            PermissionRow(name: "Location", icon: "location")
            PermissionRow(name: "Microphone", icon: "mic")
            PermissionRow(name: "Notifications", icon: "bell")
            PermissionRow(name: "Photo Library", icon: "photo")
        }
    }
}

struct PermissionRow: View {
    let name: String
    let icon: String
    @State private var status = "Unknown"

    var body: some View {
        HStack {
            Label(name, systemImage: icon)
            Spacer()
            Text(status).font(.caption).foregroundStyle(.secondary)
            Button("Test") { status = "Granted (Sim)" }
        }
    }
}
