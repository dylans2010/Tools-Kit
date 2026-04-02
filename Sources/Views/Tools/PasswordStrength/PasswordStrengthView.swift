import SwiftUI
struct PasswordStrengthView: View {
    @StateObject private var backend = PasswordStrengthBackend()
    var body: some View {
        VStack(spacing: 20) {
            SecureField("Enter Password", text: $backend.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Text("Strength: \(backend.strength)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Password Strength")
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
