import SwiftUI

struct ProtobufInspectorDevTool: DevTool {
    let id = "protobuf-inspector"
    let name = "Protobuf Inspector"
    let category: DevToolCategory = .data
    let icon = "doc.text.below.ecg"
    let description = "Inspect and decode Protocol Buffer message structures"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste .proto definition") { input in
            "Fields detected:\n" + input.components(separatedBy: "\n").filter { $0.contains("=") }.joined(separator: "\n")
        }
    }
}
