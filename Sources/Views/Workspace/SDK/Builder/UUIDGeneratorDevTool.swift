import SwiftUI

struct UUIDGeneratorDevTool: DevTool {
    let id = "uuid-generator"
    let name = "UUID Generator"
    let category = DevToolCategory.data
    let icon = "barcode"
    let description = "Generate unique identifiers"

    func render() -> some View {
        UUIDGeneratorView()
    }
}

struct UUIDGeneratorView: View {
    @State private var currentUUID = UUID().uuidString
    @State private var uppercase = true

    var body: some View {
        Form {
            Section("Generated UUID") {
                Text(uppercase ? currentUUID.uppercased() : currentUUID.lowercased())
                    .font(.monospaced(.body)())
                    .textSelection(.enabled)

                Button("Generate New") {
                    currentUUID = UUID().uuidString
                }
            }

            Section("Settings") {
                Toggle("Uppercase", isOn: $uppercase)
            }

            Section {
                Button {
                    UIPasteboard.general.string = uppercase ? currentUUID.uppercased() : currentUUID.lowercased()
                } label: {
                    Label("Copy to Clipboard", systemImage: "doc.on.doc")
                }
            }
        }
    }
}
