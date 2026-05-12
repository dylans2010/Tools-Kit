import SwiftUI

struct PasswordGeneratorView: View {
    @StateObject private var backend = PasswordGeneratorBackend()

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Length")
                        Spacer()
                        Text("\(Int(backend.length))").bold()
                            .foregroundColor(.blue)
                    }
                    Slider(value: $backend.length, in: 4...64, step: 1)
                }
                Toggle("Include Uppercase", isOn: $backend.includeUppercase)
                Toggle("Include Numbers", isOn: $backend.includeNumbers)
                Toggle("Include Special Characters", isOn: $backend.includeSpecial)
            } header: {
                Text("Configuration")
            } footer: {
                Text("Adjust the length and character sets to meet your security requirements.")
            }

            Section {
                if !backend.password.isEmpty {
                    VStack(spacing: 16) {
                        Text(backend.password)
                            .font(.system(.title3, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .textSelection(.enabled)

                        HStack(spacing: 12) {
                            Button(action: backend.generate) {
                                Label("Regenerate", systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            Button(action: { UIPasteboard.general.string = backend.password }) {
                                Image(systemName: "doc.on.doc")
                                    .padding(.horizontal)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Button(action: backend.generate) {
                        Text("Generate Password")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } header: {
                Text("Result")
            } footer: {
                if !backend.password.isEmpty {
                    Text("Your new password is ready. Copy it or regenerate a new one.")
                }
            }
        }
        .navigationTitle("Password Generator")
    }
}

struct PasswordGeneratorTool: Tool, Sendable {
    let name = "Password Generator"
    let icon = "key"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Generate secure, random passwords with custom requirements"
    let requiresAPI = false
    var view: AnyView { AnyView(PasswordGeneratorView()) }
}
