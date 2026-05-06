import SwiftUI

struct SDKToolsView: View {
    @StateObject private var toolManager = SDKToolManager.shared
    @State private var selectedTool: SDKTool?

    var body: some View {
        List {
            ForEach(ToolCategory.allCases, id: \.self) { category in
                Section(category.rawValue.capitalized) {
                    ForEach(toolManager.tools(for: category)) { tool in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tool.name).font(.headline)
                                Text("\(tool.inputSchema.count) inputs").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Run") {
                                selectedTool = tool
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .navigationTitle("Tools")
        .sheet(item: $selectedTool) { tool in
            ToolRunnerView(tool: tool)
        }
    }
}

struct ToolRunnerView: View {
    let tool: SDKTool
    @State private var inputs: [String: String] = [:]
    @State private var result: SDKToolResult?
    @State private var isRunning = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Inputs") {
                    ForEach(tool.inputSchema, id: \.key) { param in
                        HStack {
                            Text(param.key).font(.subheadline)
                            if param.required {
                                Text("*").foregroundStyle(.red)
                            }
                            Spacer()
                            TextField(param.type, text: Binding(
                                get: { inputs[param.key] ?? "" },
                                set: { inputs[param.key] = $0 }
                            ))
                            .multilineTextAlignment(.trailing)
                        }
                    }
                }

                if isRunning {
                    HStack {
                        Spacer()
                        ProgressView("Running...")
                        Spacer()
                    }
                }

                if let result = result {
                    Section("Output") {
                        Text(String(describing: result.output))
                            .font(.system(.body, design: .monospaced))
                        LabeledContent("Duration", value: String(format: "%.3f s", result.duration))
                        LabeledContent("Success", value: result.success ? "Yes" : "No")
                    }
                }

                Section {
                    Button(action: runTool) {
                        Text("Execute Tool")
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isRunning)
                }
            }
            .navigationTitle(tool.name)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }

    private func runTool() {
        isRunning = true
        Task {
            do {
                let res = try await SDKToolManager.shared.execute(toolID: tool.id, input: inputs)
                await MainActor.run {
                    self.result = res
                    self.isRunning = false
                }
            } catch {
                await MainActor.run {
                    self.isRunning = false
                    SDKLogStore.shared.log("Tool failed: \(error.localizedDescription)", source: "ToolRunner", level: .error)
                }
            }
        }
    }
}
