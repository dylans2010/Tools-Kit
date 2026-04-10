import SwiftUI

struct SmartAutofillView: View {
    @State private var context = ""
    @State private var field = ""
    @State private var generatedContent = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let aiService = AIService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Context (e.g. Email from a client)").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $context)
                        .frame(height: 150)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }

                TextField("Field to fill (e.g. Response Email)", text: $field)
                    .textFieldStyle(.roundedBorder)

                Button(action: { Task { await autofill() } }) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Generate Content")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(context.isEmpty || field.isEmpty || isLoading)

                if let error = errorMessage {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                if !generatedContent.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Suggested Content").font(.headline)
                        TextEditor(text: .constant(generatedContent))
                            .frame(height: 200)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    }
                }

                Spacer()
            }
            .padding()
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
