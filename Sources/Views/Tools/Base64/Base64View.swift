import SwiftUI

struct Base64View: View {
    @StateObject private var backend = Base64Backend()

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter plain text to encode into Base64, or a Base64 string to decode back to plain text.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $backend.inputText)
                        .frame(minHeight: 120)
                        .font(.body.monospaced())
                }
            } header: {
                Text("Input Data")
            }

            Section {
                HStack(spacing: 16) {
                    Button(action: backend.encode) {
                        Label("Encode", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: backend.decode) {
                        Label("Decode", systemImage: "arrow.left.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
            }

            if !backend.outputText.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(backend.outputText)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .textSelection(.enabled)

                        HStack {
                            Button(action: { UIPasteboard.general.string = backend.outputText }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button(action: backend.clear) {
                                Label("Clear", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Result")
                } footer: {
                    Text("Conversion complete. Input: \(backend.inputText.count) chars • Output: \(backend.outputText.count) chars")
                }
            }
        }
        .navigationTitle("Base64 Tool")
    }
}

struct Base64Tool: Tool {
    let name = "Base64 Tool"
    let icon = "lock.open"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Encode and decode Base64 strings"
    let requiresAPI = false
    var view: AnyView { AnyView(Base64View()) }
}
