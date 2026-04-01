import SwiftUI
struct PasswordStrengthView: View {
    @StateObject private var backend = PasswordStrengthBackend()
    var body: some View { VStack { SecureField("Pass", text: $backend.password); Text("Strength: \(backend.strength)") }.navigationTitle("Pass Strength") }
}
struct PasswordStrengthTool: Tool {
    let name = "Password Strength"
    let icon = "lock.shield"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Check password strength"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 1
    var view: AnyView { AnyView(PasswordStrengthView()) }
}
