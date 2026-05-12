import SwiftUI

struct PasswordStrengthView: View {
    @StateObject private var backend = PasswordStrengthBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Analyze your password's resistance to brute-force attacks.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.blue)
                            SecureField("Enter password to test", text: $backend.password)
                                .font(.body.monospaced())
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }

                Section {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Security Level")
                                .font(.headline)
                            Spacer()
                            Text(backend.strengthLabel)
                                .font(.headline)
                                .foregroundColor(colorFromString(backend.strengthColor))
                        }

                        ProgressView(value: min(backend.entropy, 128), total: 128)
                            .accentColor(colorFromString(backend.strengthColor))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .animation(.spring(), value: backend.entropy)

                        Text("\(Int(backend.entropy)) bits of entropy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Detailed Analysis")
                            .font(.headline)

                        Text("Meeting these criteria significantly increases your password's complexity.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            StrengthCriteriaRow(label: "Minimum 12 characters (\(backend.password.count))", met: backend.password.count >= 12)
                            StrengthCriteriaRow(label: "Include uppercase & lowercase", met: backend.password.rangeOfCharacter(from: .lowercaseLetters) != nil && backend.password.rangeOfCharacter(from: .uppercaseLetters) != nil)
                            StrengthCriteriaRow(label: "Include numeric digits", met: backend.password.rangeOfCharacter(from: .decimalDigits) != nil)
                            StrengthCriteriaRow(label: "Include special symbols", met: backend.password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()-_=+[]{}|;:,.<>?")) != nil)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
        }
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

struct PasswordStrengthTool: Tool, Sendable {
    let name = "Password Strength"
    let icon = "lock.shield"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Analyze the security and entropy of your passwords"
    let requiresAPI = false
    var view: AnyView { AnyView(PasswordStrengthView()) }
}
