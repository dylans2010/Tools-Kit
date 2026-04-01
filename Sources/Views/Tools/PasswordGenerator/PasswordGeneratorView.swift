import SwiftUI

struct PasswordGeneratorView: View {
    @StateObject private var backend = PasswordGeneratorBackend()

    var body: some View {
        Form {
            Section(header: Text("Options")) {
                Slider(value: $backend.length, in: 8...32, step: 1)
                Text("Length: \(Int(backend.length))")
                Toggle("Include Uppercase", isOn: $backend.includeUppercase)
                Toggle("Include Numbers", isOn: $backend.includeNumbers)
                Toggle("Include Special", isOn: $backend.includeSpecial)
            }

            Section(header: Text("Generated Password")) {
                Text(backend.password)
                    .font(.system(.title3, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()

                Button("Generate") {
                    backend.generate()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Password Generator")
    }
}

struct PasswordGeneratorTool: Tool {
    let name = "Password Generator"
    let icon = "key"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Secure, random password generator"

    var view: AnyView {
        AnyView(PasswordGeneratorView())
    }
}
