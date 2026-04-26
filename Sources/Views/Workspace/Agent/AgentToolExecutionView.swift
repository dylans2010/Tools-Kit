import SwiftUI

struct AgentToolExecutionView: View {
    @ObservedObject var state: AgentSessionState
    @State private var selectedTool: AgentToolExecution?

    var body: some View {
        List {
            if state.toolExecutions.isEmpty {
                ContentUnavailableView(
                    "No Tools Executed",
                    systemImage: "hammer",
                    description: Text("Wait for the agent to start calling system tools.")
                )
            } else {
                ForEach(state.toolExecutions.reversed()) { execution in
                    ToolExecutionRow(execution: execution)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTool = execution
                        }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Tool Executions")
        .sheet(item: $selectedTool) { execution in
            AgentToolExecutionDetailView(execution: execution)
        }
    }
}

struct ToolExecutionRow: View {
    let execution: AgentToolExecution

    var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(execution.tool)
                    .font(.subheadline.bold())
                Text(execution.requestId)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let error = execution.error {
                let _ = error // Use error to avoid warning
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var statusIcon: some View {
        let color: Color = {
            switch execution.status {
            case "success": return .green
            case "error": return .red
            default: return .orange
            }
        }()

        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

struct AgentToolExecutionDetailView: View {
    let execution: AgentToolExecution
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionView(title: "Request ID", content: execution.requestId, monospaced: true)
                    SectionView(title: "Status", content: execution.status.uppercased())

                    if let error = execution.error {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(error.message)
                                .font(.subheadline)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    JsonSectionView(title: "Input", data: execution.input)
                    JsonSectionView(title: "Output", data: execution.output)
                }
                .padding()
            }
            .navigationTitle(execution.tool)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SectionView: View {
    let title: String
    let content: String
    var monospaced: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(monospaced ? .system(.subheadline, design: .monospaced) : .subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct JsonSectionView: View {
    let title: String
    let data: [String: AnyCodable]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            if let jsonString = prettyPrint(data) {
                Text(jsonString)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func prettyPrint(_ dict: [String: AnyCodable]) -> String? {
        do {
            let data = try JSONEncoder().encode(dict)
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            return String(data: prettyData, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
