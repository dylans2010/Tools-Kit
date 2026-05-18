import SwiftUI

struct UUIDGeneratorTool: DevTool {
    let id = UUID()
    let name = "UUID Generator"
    let category: DevToolCategory = .data
    let icon = "number.square"
    let description = "Generate unique UUIDs"
    func render() -> some View { UUIDGeneratorDevToolView() }
}

struct UUIDGeneratorDevToolView: View {
    @State private var generated = UUID().uuidString
    @State private var uppercase = true
    var body: some View {
        Form {
            Section("Generated UUID") {
                Text(uppercase ? generated.uppercased() : generated.lowercased())
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
            Section {
                Toggle("Uppercase", isOn: $uppercase)
                Button("Generate New") { generated = UUID().uuidString }
            }
            Section("Versions") {
                LabeledContent("Version", value: "4 (Random)")
                LabeledContent("Length", value: "\(generated.count) characters")
                LabeledContent("Bytes", value: "16")
            }
        }
        .navigationTitle("UUID Generator")
    }
}
