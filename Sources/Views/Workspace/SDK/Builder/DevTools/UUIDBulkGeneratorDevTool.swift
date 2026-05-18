import SwiftUI

struct UUIDBulkGeneratorTool: DevTool {
    let id = UUID()
    let name = "UUID Bulk Generator"
    let category: DevToolCategory = .data
    let icon = "list.number"
    let description = "Generate multiple UUIDs at once"
    func render() -> some View { UUIDBulkGeneratorDevToolView() }
}

struct UUIDBulkGeneratorDevToolView: View {
    @State private var count: Double = 10
    @State private var uuids: [String] = []
    @State private var uppercase = true
    var body: some View {
        Form {
            Section("Configuration") {
                LabeledContent("Count: \(Int(count))") { Slider(value: $count, in: 1...100, step: 1) }
                Toggle("Uppercase", isOn: $uppercase)
                Button("Generate") {
                    uuids = (0..<Int(count)).map { _ in
                        let u = UUID().uuidString
                        return uppercase ? u : u.lowercased()
                    }
                }
            }
            if !uuids.isEmpty {
                Section("Generated (\(uuids.count))") {
                    ForEach(Array(uuids.enumerated()), id: \.offset) { idx, uuid in
                        HStack {
                            Text("\(idx + 1).").font(.caption).foregroundStyle(.secondary).frame(width: 30)
                            Text(uuid).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .navigationTitle("UUID Bulk Generator")
    }
}
