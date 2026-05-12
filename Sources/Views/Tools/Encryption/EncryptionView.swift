import SwiftUI

struct EncryptionView: View {
    @StateObject private var backend = EncryptionBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Input Text / Base64").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $backend.inputText)
                        .frame(height: 120)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }

                VStack(alignment: .leading) {
                    Text("Secret Key").font(.caption).foregroundColor(.secondary)
                    SecureField("Enter key", text: $backend.keyText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack(spacing: 12) {
                    Button(action: backend.encrypt) {
                        Label("Encrypt", systemImage: "lock.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: backend.decrypt) {
                        Label("Decrypt", systemImage: "lock.open.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if let error = backend.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Output").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Button(action: { UIPasteboard.general.string = backend.outputText }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .disabled(backend.outputText.isEmpty)
                    }
                    TextEditor(text: .constant(backend.outputText))
                        .frame(height: 120)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.2)))
                }

                Button("Clear All", role: .destructive) {
                    backend.clear()
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Text Encryption")
    }
}

struct EncryptionTool: Tool, Sendable {
    let name = "Text Encryption"
    let icon = "lock.doc"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Securely encrypt and decrypt text using AES-GCM"
    let requiresAPI = false
    var view: AnyView { AnyView(EncryptionView()) }
}
