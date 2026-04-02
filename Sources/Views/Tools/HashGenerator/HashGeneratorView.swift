import SwiftUI

struct HashGeneratorView: View {
    @StateObject private var backend = HashGeneratorBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Input Text").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $backend.inputText)
                        .frame(height: 120)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }

                VStack(alignment: .leading) {
                    Text("Algorithm").font(.caption).foregroundColor(.secondary)
                    Picker("Algorithm", selection: $backend.selectedAlgorithm) {
                        ForEach(HashAlgorithm.allCases) { algo in
                            Text(algo.rawValue).tag(algo)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button(action: backend.generate) {
                    Text("Generate Hash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.inputText.isEmpty)

                if !backend.resultHash.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Generated \(backend.selectedAlgorithm.rawValue) Hash").font(.headline)
                            Spacer()
                            Button(action: { UIPasteboard.general.string = backend.resultHash }) {
                                Image(systemName: "doc.on.doc")
                            }
                        }

                        Text(backend.resultHash)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .textSelection(.enabled)
                    }
                }

                Button("Clear", role: .destructive) {
                    backend.clear()
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Hash Generator")
    }
}

struct HashGeneratorTool: Tool {
    let name = "Hash Generator"
    let icon = "number.square"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Generate secure MD5, SHA-1, SHA-256, and SHA-512 hashes"
    let requiresAPI = false
    var view: AnyView { AnyView(HashGeneratorView()) }
}
