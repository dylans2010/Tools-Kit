import SwiftUI

struct DeveloperJSONFormatterView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var errorMessage: String?
    @State private var indentSize = 2

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Input JSON").font(.headline)
                TextEditor(text: $inputText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            }
            .padding()

            HStack {
                Picker("Indent", selection: $indentSize) {
                    Text("2 Spaces").tag(2)
                    Text("4 Spaces").tag(4)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                Button("Format") {
                    formatJSON()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
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

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                ScrollView {
                    Text(outputText.isEmpty ? "Formatted JSON will appear here" : outputText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(maxHeight: .infinity)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            }
            .padding()
        }
        .navigationTitle("JSON Formatter")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func formatJSON() {
        errorMessage = nil
        guard let data = inputText.data(using: .utf8) else {
            errorMessage = "Invalid input encoding"
            return
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
            let outputData = try JSONSerialization.data(withJSONObject: json, options: options)
            if var result = String(data: outputData, encoding: .utf8) {
                if indentSize == 2 {
                    result = result.replacingOccurrences(of: "    ", with: "  ")
                }
                outputText = result
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
}
