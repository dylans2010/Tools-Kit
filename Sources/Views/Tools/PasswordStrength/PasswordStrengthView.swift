import SwiftUI

struct PasswordStrengthView: View {
    @StateObject private var backend = PasswordStrengthBackend()

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading) {
                Text("Password").font(.caption).foregroundColor(.secondary)
                SecureField("Enter password to test", text: $backend.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body.monospaced())
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Security Level:")
                    Spacer()
                    Text(backend.strengthLabel)
                        .bold()
                        .foregroundColor(colorFromString(backend.strengthColor))
                }

                ProgressView(value: min(backend.entropy, 128), total: 128)
                    .accentColor(colorFromString(backend.strengthColor))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text("Why this score?").font(.headline)
                Text("Strength is calculated based on entropy (bit-length). A higher entropy means it's harder for a computer to guess your password.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                StrengthCriteriaRow(label: "Length (\(backend.password.count))", met: backend.password.count >= 12)
                StrengthCriteriaRow(label: "Mixed Case", met: backend.password.rangeOfCharacter(from: .lowercaseLetters) != nil && backend.password.rangeOfCharacter(from: .uppercaseLetters) != nil)
                StrengthCriteriaRow(label: "Numbers", met: backend.password.rangeOfCharacter(from: .decimalDigits) != nil)
                StrengthCriteriaRow(label: "Special Characters", met: backend.password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()-_=+[]{}|;:,.<>?")) != nil)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Password Strength")
    }

    private func colorFromString(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        default: return .gray
        }
    }
}

struct StrengthCriteriaRow: View {
    let label: String
    let met: Bool

    var body: some View {
        HStack {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .secondary)
            Text(label)
                .font(.subheadline)
                .foregroundColor(met ? .primary : .secondary)
            Spacer()
        }
    }
}

struct PasswordStrengthTool: Tool {
    let name = "Password Strength"
    let icon = "lock.shield"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Analyze the security and entropy of your passwords"
    let requiresAPI = false
    var view: AnyView { AnyView(PasswordStrengthView()) }
}
