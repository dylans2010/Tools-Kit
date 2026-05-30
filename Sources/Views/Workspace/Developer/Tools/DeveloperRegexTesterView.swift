import SwiftUI

struct DeveloperRegexTesterView: View {
    @State private var pattern = ""
    @State private var testText = ""
    @State private var matches: [String] = []
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Regex Pattern").font(.headline)
                    TextField("e.g. [a-z0-9]+", text: $pattern)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.subheadline, design: .monospaced))
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .onChange(of: pattern) { _ in runRegex() }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Text").font(.headline)
                    TextEditor(text: $testText)
                        .font(.system(.subheadline, design: .monospaced))
                        .frame(height: 120)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                        .onChange(of: testText) { _ in runRegex() }
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

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Matches (\(matches.count))").font(.headline)
                        Spacer()
                    }

                    if matches.isEmpty {
                        Text("No matches found").font(.caption).foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 1) {
                            ForEach(Array(matches.enumerated()), id: \.offset) { _, match in
                                Text(match)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.1)))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Regex Tester")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func runRegex() {
        errorMessage = nil
        matches = []

        guard !pattern.isEmpty else { return }

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(testText.startIndex..<testText.endIndex, in: testText)
            let results = regex.matches(in: testText, options: [], range: nsRange)

            matches = results.map { result in
                if let range = Range(result.range, in: testText) {
                    return String(testText[range])
                }
                return ""
            }.filter { !$0.isEmpty }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
