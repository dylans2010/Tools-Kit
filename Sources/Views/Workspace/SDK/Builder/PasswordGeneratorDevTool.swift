import SwiftUI

struct PasswordGeneratorDevTool: DevTool {
    let id = "password-generator"
    let name = "Password Generator"
    let category: DevToolCategory = .security
    let icon = "key.horizontal"
    let description = "Generate secure random passwords with custom rules"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter length (default: 16)") { input in
            let length = Int(input) ?? 16
            let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
            return String((0..<min(length, 128)).map { _ in chars.randomElement()! })
        }
    }
}
