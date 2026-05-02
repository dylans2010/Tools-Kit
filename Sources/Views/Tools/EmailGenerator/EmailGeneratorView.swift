import SwiftUI

struct EmailGeneratorView: View {
    @StateObject private var backend = EmailGeneratorBackend()

    var body: some View {
        Form {
            Section {
                Picker("Email Type", selection: $backend.selectedType) {
                    ForEach(EmailType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                Picker("Tone", selection: $backend.selectedTone) {
                    ForEach(EmailTone.allCases, id: \.self) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }

                TextField("Recipient Name", text: $backend.recipientName)
                TextField("Your Name", text: $backend.senderName)
                TextField("Context / Topic", text: $backend.contextInfo)
            } header: {
                Text("Configuration")
            }

            Section {
                Button {
                    Task { await backend.generate() }
                } label: {
                    if backend.isProcessing {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Generate Email")
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isProcessing)
            }

            if !backend.generatedEmail.isEmpty {
                Section {
                    TextEditor(text: .constant(backend.generatedEmail))
                        .frame(height: 200)
                        .font(.body)

                    Button(action: { UIPasteboard.general.string = backend.generatedEmail }) {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }
                } header: {
                    Text("Generated Email")
                }
            }
        }
        .navigationTitle("Email Assistant")
    }
}

struct EmailGeneratorTool: Tool {
    let name = "Email Assistant"
    let icon = "envelope.open.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "Generate professional emails from templates"
    let requiresAPI = true
    var view: AnyView { AnyView(EmailGeneratorView()) }
}
