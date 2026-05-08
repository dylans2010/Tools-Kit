import SwiftUI

struct SDKToolsView: View {
    @StateObject private var manager = SDKToolManager.shared
    @State private var selectedTool: SDKTool?

    var body: some View {
        List {
            ForEach(SDKToolCategory.allCases, id: \.self) { category in
                Section(header: Text(category.rawValue.capitalized)) {
                    ForEach(manager.tools(for: category)) { tool in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tool.name).font(.headline)
                                Text("\(tool.inputSchema.count) Inputs").font(.caption).foregroundStyle(.secondary)
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

            Section {
                let history = SDKToolRuntime.shared.getHistory().prefix(10)
                if history.isEmpty {
                    Text("No Executions Yet").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(history), id: \.toolID) { record in
                        HStack {
                            Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(record.success ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(record.toolID.uuidString.prefix(8))
                                    .font(.system(.caption, design: .monospaced))
                                Text("\(String(format: "%.1fms", record.duration * 1000))")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Execution History")
            }
        }
        .navigationTitle("Tools")
        .sheet(item: $selectedTool) { tool in
            ToolRunnerView(tool: tool)
        }
    }

    private func categoryBadge(_ category: SDKToolCategory) -> some View {
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
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @State private var inputs: [String: String] = [:]
    @State private var result: SDKToolResult?
    @State private var errorMessage: String?
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(tool.inputSchema, id: \.key) { param in
                        TextField(param.key + (param.required ? " *" : ""), text: binding(for: param.key))
                    }
                } header: {
                    Text("Inputs")
                }

                Section {
                    HStack {
                        Text("Execution Mode")
                        Spacer()
                        Text(runtime.isNoSandboxModeEnabled ? "Unrestricted" : "Sandboxed")
                            .font(.caption)
                            .foregroundStyle(runtime.isNoSandboxModeEnabled ? .red : .green)
                    }
                } header: {
                    Text("Scope Validation")
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
                    .disabled(isRunning || missingRequiredInputs)
                }

                if let result = result {
                    Section {
                        if result.success {
                            ForEach(Array(result.output.keys.sorted()), id: \.self) { key in
                                VStack(alignment: .leading) {
                                    Text(key).font(.caption).foregroundStyle(.secondary)
                                    Text("\(String(describing: result.output[key] ?? ""))")
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                            Text("Duration: \(String(format: "%.2fms", result.duration * 1000))")
                                .font(.caption2).foregroundStyle(.secondary)
                        } else {
                            Text("Execution Failed").foregroundStyle(.red)
                        }
                    } header: {
                        Text("Result")
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.red)
                    } header: {
                        Text("Error")
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

    private var missingRequiredInputs: Bool {
        tool.inputSchema.filter { $0.required }.contains { param in
            (inputs[param.key] ?? "").isEmpty
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
        errorMessage = nil
        result = nil
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
                    errorMessage = error.localizedDescription
                    SDKLogStore.shared.log("Tool execution failed: \(error.localizedDescription)", source: "ToolRunnerView", level: .error)
                }
            }
        }
    }
}
