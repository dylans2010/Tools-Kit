/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Modernized tool rows using a private struct ToolRegistryRow with native Label.
 - Applied .presentationDetents([.large]) to the tool runner sheet.
 - Standardized execution history using semantic status icons and LabeledContent.
 - Replaced manual badge and button layouts with semantic components.
 - strictly preserved all SDKToolManager execution and history tracking logic.
 - Improved visual hierarchy for input schema and execution results.
 - Extracted subviews for ToolRunner and OutputSection.
 */

import SwiftUI

struct SDKToolsView: View {
    @StateObject private var manager = SDKToolManager.shared
    @State private var selectedTool: SDKTool?

    var body: some View {
        List {
            ForEach(SDKToolCategory.allCases, id: \.self) { category in
                Section(category.rawValue.capitalized) {
                    ForEach(manager.tools(for: category)) { tool in
                        ToolRegistryRow(tool: tool) { selectedTool = tool }
                    }
                }
            }

            Section("Execution History") {
                let history = SDKToolRuntime.shared.getHistory().prefix(10)
                if history.isEmpty {
                    Text("No executions recorded").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(history), id: \.toolID) { record in
                        LabeledContent {
                            Text("\(Int(record.duration * 1000))ms").font(.caption.monospaced())
                        } label: {
                            Label(record.toolID.uuidString.prefix(8).description,
                                  systemImage: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption.monospaced())
                                .foregroundStyle(record.success ? Color.green : Color.red)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Tools")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTool) { ToolRunner(tool: $0) }
    }
}

// MARK: - Private Subviews

private struct ToolRegistryRow: View {
    let tool: SDKTool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.name).font(.headline)
                    Text("\(tool.inputSchema.count) inputs").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "play.fill").font(.caption).padding(8).background(Color.accentColor.opacity(0.1), in: Circle())
            }
        }
        .buttonStyle(.plain)
    }
}

struct ToolRunner: View {
    let tool: SDKTool
    @Environment(\.dismiss) var dismiss
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @State private var inputs: [String: String] = [:]
    @State private var result: SDKToolResult?
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Input Parameters") {
                    ForEach(tool.inputSchema, id: \.key) { param in
                        TextField(param.key, text: binding(for: param.key), prompt: Text(param.required ? "Required" : "Optional"))
                    }
                }

                Section("Environment") {
                    LabeledContent("Sandbox Mode") {
                        Text(runtime.isNoSandboxModeEnabled ? "Unrestricted" : "Sandboxed")
                            .foregroundStyle(runtime.isNoSandboxModeEnabled ? Color.red : Color.green).bold()
                    }
                }

                Section {
                    Button(action: runTool) {
                        HStack {
                            if isRunning { ProgressView().controlSize(.small) }
                            Text("Execute Tool").bold()
                        }.frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).disabled(isRunning || missingRequired)
                }

                if let res = result {
                    Section("Output") {
                        if res.success {
                            ForEach(Array(res.output.keys.sorted()), id: \.self) { key in
                                LabeledContent(key) { Text("\(String(describing: res.output[key] ?? ""))").font(.caption.monospaced()) }
                            }
                        } else {
                            Label("Execution Failed", systemImage: "exclamationmark.octagon").foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(tool.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    private var missingRequired: Bool { tool.inputSchema.filter { $0.required }.contains { (inputs[$0.key] ?? "").isEmpty } }
    private func binding(for key: String) -> Binding<String> { Binding(get: { inputs[key] ?? "" }, set: { inputs[key] = $0 }) }
    private func runTool() {
        isRunning = true
        Task {
            do {
                let res = try await SDKToolManager.shared.execute(toolID: tool.id, input: inputs)
                await MainActor.run { result = res; isRunning = false }
            } catch { await MainActor.run { isRunning = false } }
        }
    }
}
