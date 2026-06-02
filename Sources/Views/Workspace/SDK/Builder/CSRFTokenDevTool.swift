import SwiftUI

struct CSRFTokenDevTool: DevTool {
    let id = "csrf-token"
    let name = "CSRF Token Generator"
    let category: DevToolCategory = .security
    let icon = "shield.lefthalf.filled"
    let description = "Generate CSRF tokens for form protection"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Generate token") { _ in UUID().uuidString.replacingOccurrences(of: "-", with: "") + UUID().uuidString.replacingOccurrences(of: "-", with: "") } }
}
