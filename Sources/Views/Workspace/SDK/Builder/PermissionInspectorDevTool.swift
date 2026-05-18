import SwiftUI

struct PermissionInspectorDevTool: DevTool {
    let id = "permission-inspector"
    let name = "Permission Inspector"
    let category = DevToolCategory.security
    let icon = "lock.shield"
    let description = "Check system permission statuses"

    func render() -> some View {
        PermissionInspectorView()
    }
}

struct PermissionInspectorView: View {
    var body: some View {
        List {
            Section("System Scopes") {
                LabeledContent("Motion", value: "Available")
                LabeledContent("Background App Refresh", value: stateString)
            }
        }
    }

    var stateString: String {
        switch UIApplication.shared.backgroundRefreshStatus {
        case .available: return "Available"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
        }
    }
}
