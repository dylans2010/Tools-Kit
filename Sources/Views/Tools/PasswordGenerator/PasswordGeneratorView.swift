import SwiftUI

struct PasswordGeneratorView: View {
    @StateObject private var backend = PasswordGeneratorBackend()

    var body: some View {
        Form {
            Section(header: Text("Options")) {
                VStack {
                    HStack {
                        Text("Length")
                        Spacer()
                        Text("\(Int(backend.length))").bold()
                    }
                    Slider(value: $backend.length, in: 4...64, step: 1)
                }
                Toggle("Include Uppercase", isOn: $backend.includeUppercase)
                Toggle("Include Numbers", isOn: $backend.includeNumbers)
                Toggle("Include Special Characters", isOn: $backend.includeSpecial)
            }

            Section(header: Text("Generated Password")) {
                if !backend.password.isEmpty {
                    Text(backend.password)
                        .font(.system(.title3, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .textSelection(.enabled)
                }

                HStack {
                    Button(action: backend.generate) {
                        Text("Generate")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if !backend.password.isEmpty {
                        Button(action: { UIPasteboard.general.string = backend.password }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }
                }
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
    let description = "Generate secure, random passwords with custom requirements"
    let requiresAPI = false
    var view: AnyView { AnyView(PasswordGeneratorView()) }
}
