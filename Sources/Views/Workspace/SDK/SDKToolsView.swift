import SwiftUI

struct SDKToolsView: View {
    @StateObject private var manager = SDKToolManager.shared
    @State private var selectedTool: SDKTool?

    var body: some View {
        List {
            ForEach(ToolCategory.allCases, id: \.self) { category in
                Section(header: Text(category.rawValue.capitalized)) {
                    ForEach(manager.tools(for: category)) { tool in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tool.name).font(.headline)
                                Text("\(tool.inputSchema.count) inputs").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            categoryBadge(category)
                            Button("Run") {
                                selectedTool = tool
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
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

    private func categoryBadge(_ category: ToolCategory) -> some View {
        Text(category.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.1), in: Capsule())
    }
}

struct ToolRunnerView: View {
    let tool: SDKTool
    @Environment(\.dismiss) var dismiss
    @State private var inputs: [String: String] = [:]
    @State private var result: SDKToolResult?
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Inputs") {
                    ForEach(tool.inputSchema, id: \.key) { param in
                        TextField(param.key + (param.required ? "*" : ""), text: binding(for: param.key))
                    }
                }

                Section {
                    Button {
                        runTool()
                    } label: {
                        if isRunning {
                            ProgressView().progressViewStyle(.circular)
                        } else {
                            Text("Execute")
                        }
                    }
                    .disabled(isRunning)
                }

                if let result = result {
                    Section("Result") {
                        if result.success {
                            ForEach(Array(result.output.keys), id: \.self) { key in
                                VStack(alignment: .leading) {
                                    Text(key).font(.caption).foregroundStyle(.secondary)
                                    Text("\(String(describing: result.output[key] ?? ""))")
                                }
                            }
                            Text("Duration: \(String(format: "%.2fms", result.duration * 1000))")
                                .font(.caption2).foregroundStyle(.secondary)
                        } else {
                            Text("Execution failed").foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(tool.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { inputs[key] ?? "" },
            set: { inputs[key] = $0 }
        )
    }

    private func runTool() {
        isRunning = true
        Task {
            do {
                let res = try await SDKToolManager.shared.execute(toolID: tool.id, input: inputs)
                await MainActor.run {
                    self.result = res
                    isRunning = false
                }
            } catch {
                await MainActor.run {
                    isRunning = false
                    // Handle error
                }
            }
        }
    }
}
