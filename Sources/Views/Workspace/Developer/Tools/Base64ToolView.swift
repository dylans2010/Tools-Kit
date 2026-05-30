import SwiftUI

struct Base64ToolView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isEncoding = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Operation", selection: $isEncoding) {
                    Text("Encode").tag(true)
                    Text("Decode").tag(false)
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Input").font(.headline)
                    TextEditor(text: $inputText)
                        .font(.system(.subheadline, design: .monospaced))
                        .frame(minHeight: 150)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }

                Button(action: process) {
                    Text(isEncoding ? "Encode to Base64" : "Decode from Base64")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Output").font(.headline)
                        Spacer()
                        if !outputText.isEmpty {
                            Button {
                                UIPasteboard.general.string = outputText
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    }

                    Text(outputText.isEmpty ? "Result will appear here" : outputText)
                        .font(.system(.subheadline, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            .padding()
        }
        .navigationTitle("Base64 Tool")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func process() {
        errorMessage = nil
        if isEncoding {
            let data = inputText.data(using: .utf8)
            outputText = data?.base64EncodedString() ?? ""
        } else {
            if let data = Data(base64Encoded: inputText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                if let decoded = String(data: data, encoding: .utf8) {
                    outputText = decoded
                } else {
                    errorMessage = "Decoded data is not valid UTF-8 text"
                    outputText = ""
                }
            } else {
                errorMessage = "Invalid Base64 string"
                outputText = ""
            }
        }
    }
}
