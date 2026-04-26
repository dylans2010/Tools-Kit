import SwiftUI

struct RunWorkflowView: View {
    let owner: String
    let repo: String
    let workflowID: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = WorkflowManager()
    @State private var ref = "main"
    @State private var inputKey = ""
    @State private var inputValue = ""
    @State private var inputs: [String: String] = [:]
    @State private var status = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Target") {
                    TextField("Ref", text: $ref)
                }
                Section("Inputs") {
                    HStack {
                        TextField("Key", text: $inputKey)
                        TextField("Value", text: $inputValue)
                    }
                    Button("Add Input") {
                        guard !inputKey.isEmpty else { return }
                        inputs[inputKey] = inputValue
                        inputKey = ""
                        inputValue = ""
                    }
                    ForEach(inputs.keys.sorted(), id: \.self) { key in
                        Text("\(key): \(inputs[key] ?? "")")
                    }
                }
                if !status.isEmpty {
                    Section("Status") { Text(status) }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Run") {
                        Task {
                            let ok = await manager.trigger(workflowID: workflowID, owner: owner, repo: repo, ref: ref, inputs: inputs)
                            status = ok ? "Workflow dispatched." : (manager.lastError ?? "Dispatch failed")
                        }
                    }
                }
            }
        }
    }
}
