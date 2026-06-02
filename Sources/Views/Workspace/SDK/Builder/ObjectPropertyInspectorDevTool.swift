import SwiftUI

struct ObjectPropertyInspectorDevTool: DevTool {
    let id = "object-property-inspector"
    let name = "Object Property Inspector"
    let category: DevToolCategory = .debugging
    let icon = "magnifyingglass"
    let description = "Inspect public properties of Any object (simulated)"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter object description") { input in
            "Properties detected for '\(input)':\n- id: UUID\n- name: String\n- createdAt: Date\n- isActive: Bool"
        }
    }
}
