import SwiftUI

struct URLEncoderView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isEncoding = true

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
                    Text(isEncoding ? "URL Encode" : "URL Decode")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .navigationTitle("URL Encoder")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func process() {
        if isEncoding {
            outputText = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        } else {
            outputText = inputText.removingPercentEncoding ?? ""
        }
    }
}
