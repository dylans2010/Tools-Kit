import SwiftUI

struct SmartAutofillView: View {
    @State private var prompt = ""
    @State private var generatedContent = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("What should I generate? (e.g. Email template)", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button("Generate Content") {
                generatedContent = "Here is your generated content based on your request..."
            }
            .buttonStyle(.borderedProminent)

            if !generatedContent.isEmpty {
                VStack(alignment: .leading) {
                    Text("Result").font(.headline)
                    TextEditor(text: .constant(generatedContent))
                        .frame(height: 200)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }
                .padding()
            }

            Spacer()
        }
        .navigationTitle("Smart Autofill")
    }
}

struct SmartAutofillTool: Tool {
    let name = "Smart Autofill"
    let icon = "square.and.pencil"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "AI generator for templates, emails, and repetitive text"
    let requiresAPI = true
    var view: AnyView { AnyView(SmartAutofillView()) }
}
