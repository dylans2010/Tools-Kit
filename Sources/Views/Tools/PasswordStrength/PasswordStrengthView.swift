import SwiftUI
struct PasswordStrengthView: View {
    @StateObject private var backend = PasswordStrengthBackend()
    var body: some View {
        Form {
            Section(header: Text("Password")) {
                SecureField("Enter password", text: $backend.password)
            }
            Section(header: Text("Strength")) {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: backend.strength)
                        .tint(strengthColor)
                    Text(strengthLabel)
                        .font(.headline)
                        .foregroundColor(strengthColor)
                }
            }
        }
        .navigationTitle("Password Strength")
    }
    private var strengthColor: Color {
        backend.strength >= 1.0 ? .green : (backend.strength >= 0.7 ? .orange : .red)
    }
    private var strengthLabel: String {
        backend.strength >= 1.0 ? "Strong" : (backend.strength >= 0.7 ? "Medium" : "Weak")
    }
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
