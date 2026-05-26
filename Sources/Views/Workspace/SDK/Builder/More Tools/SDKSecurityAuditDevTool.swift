import SwiftUI

struct SDKSecurityAuditDevTool: DevTool {
    let id = "sdk-security-audit"
    let name = "SDK Security Audit"
    let category = DevToolCategory.security
    let icon = "shield.checkerboard"
    let description = "Run security scans on SDK source and dependencies"

    func render() -> some View {
        SDKPipelineOptimizerView() // Reuse or specific
    }
}
