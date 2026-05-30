import SwiftUI

struct DeveloperPasswordGeneratorView: View {
    @State private var length = 16
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var generatedPassword = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 1) {
                    HStack {
                        Text(generatedPassword.isEmpty ? "Click Generate" : generatedPassword)
                            .font(.system(.title3, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Spacer()
                        if !generatedPassword.isEmpty {
                            Button {
                                UIPasteboard.general.string = generatedPassword
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor.opacity(0.3)))

                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings").font(.headline)

                    VStack(alignment: .leading) {
                        Text("Length: \(length)").font(.subheadline)
                        Slider(value: Binding(get: { Double(length) }, set: { length = Int($0) }), in: 4...64, step: 1)
                    }

                    Divider()

                    Toggle("Uppercase (A-Z)", isOn: $includeUppercase)
                    Toggle("Lowercase (a-z)", isOn: $includeLowercase)
                    Toggle("Numbers (0-9)", isOn: $includeNumbers)
                    Toggle("Symbols (!@#$%^&*)", isOn: $includeSymbols)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: generate) {
                    Text("Generate Password")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!includeUppercase && !includeLowercase && !includeNumbers && !includeSymbols)
            }
            .padding()
        }
        .navigationTitle("Password Generator")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear(perform: generate)
    }

    private func generate() {
        let upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lower = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?"

        var charset = ""
        if includeUppercase { charset += upper }
        if includeLowercase { charset += lower }
        if includeNumbers { charset += numbers }
        if includeSymbols { charset += symbols }

        guard !charset.isEmpty else { return }

        var result = ""
        for _ in 0..<length {
            let randomIndex = Int.random(in: 0..<charset.count)
            let char = charset[charset.index(charset.startIndex, offsetBy: randomIndex)]
            result.append(char)
        }
        generatedPassword = result
    }
}
