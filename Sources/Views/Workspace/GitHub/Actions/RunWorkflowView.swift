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

    private func validateInputKey(_ key: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: "^[A-Za-z_][A-Za-z0-9_-]*$", options: [])
        let range = NSRange(location: 0, length: key.utf16.count)
        return regex?.firstMatch(in: key, options: [], range: range) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Target") {
                    Text("Repo: \(owner)/\(repo)")
                    TextField("Branch / Ref", text: $ref)
                }
                Section("Manual Inputs") {
                    HStack {
                        TextField("Key", text: $inputKey)
                        TextField("Value", text: $inputValue)
                    }
                    Button("Add Input") {
                        let key = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard validateInputKey(key) else {
                            status = "Invalid input key: \(key)"
                            return
                        }
                        inputs[key] = inputValue
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
            .navigationTitle("Run Workflow")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Run") {
                        let cleanedRef = ref.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleanedRef.isEmpty else {
                            status = "Ref is required"
                            return
                        }
                        Task {
                            let ok = await manager.trigger(workflowID: workflowID, owner: owner, repo: repo, ref: cleanedRef, inputs: inputs)
                            status = ok ? "Workflow dispatched." : (manager.lastError ?? "Dispatch failed")
                        }
                    }
                }
            }
        }
    }
}
