import SwiftUI

struct SmartAutofillView: View {
    @State private var context = ""
    @State private var field = ""
    @State private var generatedContent = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let aiService = AIService()

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste the source information (email, notes, or raw data) that the AI should use as context.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $context)
                        .frame(minHeight: 120)
                        .cornerRadius(8)
                }
            } header: {
                Text("Input Context")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What should the AI generate? (e.g., 'A polite decline email', 'A summary of action items').")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Goal or field name", text: $field)
                }
            } header: {
                Text("Target Field")
            }

            Section {
                Button(action: { Task { await autofill() } }) {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Text("Generate Suggestions")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(context.isEmpty || field.isEmpty || isLoading)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            if !generatedContent.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        TextEditor(text: .constant(generatedContent))
                            .frame(minHeight: 200)
                            .font(.body)

                        HStack {
                            Button(action: { UIPasteboard.general.string = generatedContent }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button("Clear") {
                                generatedContent = ""
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("AI Suggestion")
                } footer: {
                    Text("Review the generated content and copy it to your clipboard.")
                }
            }
        }
        .navigationTitle("Smart Autofill")
    }

    private func autofill() async {
        isLoading = true
        errorMessage = nil
        do {
            generatedContent = try await aiService.autofill(context: context, field: field)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct SmartAutofillTool: Tool {
    let id = UUID()
    let name = "Smart Autofill"
    let icon = "square.and.pencil"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "AI generator for templates, emails, and repetitive text"
    let requiresAPI = true
    var view: AnyView { AnyView(SmartAutofillView()) }
}
