import SwiftUI

struct SecurityTool: Tool {
    let name = "Security Vault"
    let icon = "lock.shield.fill"
    let category = ToolCategory.privacy
    let complexity = ToolComplexity.advanced
    let description = "End-to-end encrypted vault for credentials, photos, and files."
    let requiresAPI = false
    var view: AnyView { AnyView(SecurityDashboardView()) }
}
