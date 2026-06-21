import SwiftUI

struct AFMTaskView: View {
    @State private var inputText = ""
    @State private var taskType = "Summarization"
    @State private var responseText = ""
    @State private var isProcessing = false

    let taskTypes = ["Summarization", "Sentiment Analysis", "Proofreading", "Key Points Extraction"]

    var body: some View {
        List {
            Section(header: Text("Input")) {
                Picker("Task Type", selection: $taskType) {
                    ForEach(taskTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }

                TextEditor(text: $inputText)
                    .frame(minHeight: 150)
                    .overlay(
                        Group {
                            if inputText.isEmpty {
                                Text("Enter text to process...")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                        },
                        alignment: .topLeading
                    )
            }

            Section {
                Button(action: runTask) {
                    if isProcessing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Run Native AI Task")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isProcessing || inputText.isEmpty)
            }

            if !responseText.isEmpty {
                Section(header: Text("Response")) {
                    AFMResponseView(text: responseText)
                }
            }
        }
        .navigationTitle("AI Tasks")
    }

    private func runTask() {
        isProcessing = true
        responseText = ""

        Task {
            do {
                let response = try await AFMService.shared.generateResponse(prompt: inputText, systemPrompt: "Task: \(taskType)")
                await MainActor.run {
                    self.responseText = response
                    self.isProcessing = false
                    AFMSessionManager.shared.recordMessage()
                }
            } catch {
                await MainActor.run {
                    self.responseText = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
}
