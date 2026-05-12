import SwiftUI

struct UUIDGeneratorView: View {
    @StateObject private var backend = UUIDGeneratorBackend()
    @State private var count: Double = 1

    var body: some View {
        ToolDetailView(tool: UUIDGeneratorTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Number of UUIDs") {
                    VStack {
                        HStack {
                            Text("Count: \(Int(count))")
                            Spacer()
                        }
                        Slider(value: $count, in: 1...20, step: 1)
                    }
                    .padding()
                }

                Button("Generate") {
                    backend.generate(count: Int(count))
                }
                .buttonStyle(.borderedProminent)

                if !backend.uuids.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(backend.uuids, id: \.self) { uuid in
                            ToolOutputView("UUID", value: uuid)
                        }
                    }
                }
            }
        }
    }
}

struct UUIDGeneratorTool: Tool, Sendable {
    let name = "UUID Generator"
    let icon = "barcode"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Generate unique identifiers (UUID/GUID) instantly"
    let requiresAPI = false
    var view: AnyView { AnyView(UUIDGeneratorView()) }
}
