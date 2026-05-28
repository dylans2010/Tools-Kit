import SwiftUI

struct TextDiffDevTool: DevTool {
    let id = "text-diff"
    let name = "Text Diff"
    let category = DevToolCategory.utilities
    let icon = "rectangle.2.swap"
    let description = "Compare text blocks with line and word-level diffs"

    func render() -> some View {
        TextDiffView()
    }
}

struct TextDiffView: View {
    struct DiffLine: Identifiable {
        let id = UUID()
        let text: String
        let color: Color
        let bgColor: Color
        let lineNumber: String
    }

    @StateObject private var viewModel = TextDiffViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack {
                    Text("Original").font(.caption.bold())
                    TextEditor(text: $viewModel.textA)
                        .frame(height: 130)
                        .font(.system(.caption2, design: .monospaced))
                }
                VStack {
                    Text("Modified").font(.caption.bold())
                    TextEditor(text: $viewModel.textB)
                        .frame(height: 130)
                        .font(.system(.caption2, design: .monospaced))
                }
            }
            .padding(.horizontal)

            Form {
                Section(header: Text("Options")) {
                    Picker("Diff Mode", selection: $viewModel.diffMode) {
                        Text("Line").tag(DiffMode.line)
                        Text("Word").tag(DiffMode.word)
                    }
                    .pickerStyle(.segmented)

                    Toggle("Ignore whitespace", isOn: $viewModel.ignoreWhitespace)
                    Toggle("Ignore case", isOn: $viewModel.ignoreCase)
                }

                Section(header: Text("Statistics")) {
                    HStack(spacing: 16) {
                        VStack {
                            Text("\(viewModel.additions)").font(.title3.bold()).foregroundStyle(.green)
                            Text("Added").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        VStack {
                            Text("\(viewModel.deletions)").font(.title3.bold()).foregroundStyle(.red)
                            Text("Removed").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        VStack {
                            Text("\(viewModel.unchanged)").font(.title3.bold()).foregroundStyle(.secondary)
                            Text("Unchanged").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)

                    LabeledContent("Similarity", value: String(format: "%.1f%%", viewModel.similarity))
                }

                Section(header: Text("Diff Result")) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.diffLines) { (line: TextDiffView.DiffLine) in
                                HStack(spacing: 4) {
                                    Text(line.lineNumber)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                        .frame(width: 24, alignment: .trailing)
                                    Text(line.text)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(line.color)
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(line.bgColor)
                            }
                        }
                    }
                    .frame(height: 200)

                    Button {
                        let output = viewModel.diffLines.map(\.text).joined(separator: "\n")
                        UIPasteboard.general.string = output
                    } label: {
                        Label("Copy Diff", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

enum DiffMode {
    case line, word
}

class TextDiffViewModel: ObservableObject {
    @Published var textA = "Hello World\nThis is a test\nLine three" {
        didSet { compare() }
    }
    @Published var textB = "Hello World\nThis is an updated test\nLine three\nNew line four" {
        didSet { compare() }
    }
    @Published var diffMode = DiffMode.line { didSet { compare() } }
    @Published var ignoreWhitespace = false { didSet { compare() } }
    @Published var ignoreCase = false { didSet { compare() } }
    @Published var diffLines: [TextDiffView.DiffLine] = []
    @Published var additions = 0
    @Published var deletions = 0
    @Published var unchanged = 0
    @Published var similarity: Double = 0

    private func compare() {
        switch diffMode {
        case .line: lineDiff()
        case .word: wordDiff()
        }
    }

    private func normalize(_ text: String) -> String {
        var result = text
        if ignoreWhitespace { result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) }
        if ignoreCase { result = result.lowercased() }
        return result
    }

    private func lineDiff() {
        let linesA = textA.components(separatedBy: .newlines)
        let linesB = textB.components(separatedBy: .newlines)
        var results: [TextDiffView.DiffLine] = []
        var adds = 0, dels = 0, same = 0
        let maxCount = max(linesA.count, linesB.count)
        var lineNum = 1

        for i in 0..<maxCount {
            let a = i < linesA.count ? linesA[i] : nil
            let b = i < linesB.count ? linesB[i] : nil
            let normA = a.map { normalize($0) }
            let normB = b.map { normalize($0) }

            if normA == normB {
                results.append(TextDiffView.DiffLine(text: "  " + (a ?? ""), color: .secondary, bgColor: .clear, lineNumber: "\(lineNum)"))
                same += 1
                lineNum += 1
            } else {
                if let a {
                    results.append(TextDiffView.DiffLine(text: "- " + a, color: .red, bgColor: .red.opacity(0.08), lineNumber: "\(lineNum)"))
                    dels += 1
                    lineNum += 1
                }
                if let b {
                    results.append(TextDiffView.DiffLine(text: "+ " + b, color: .green, bgColor: .green.opacity(0.08), lineNumber: "\(lineNum)"))
                    adds += 1
                    lineNum += 1
                }
            }
        }
        diffLines = results
        additions = adds; deletions = dels; unchanged = same
        let total = adds + dels + same
        similarity = total > 0 ? (Double(same) / Double(total)) * 100 : 100
    }

    private func wordDiff() {
        let wordsA = normalize(textA).split(separator: " ").map(String.init)
        let wordsB = normalize(textB).split(separator: " ").map(String.init)
        var results: [TextDiffView.DiffLine] = []
        var adds = 0, dels = 0, same = 0
        let maxCount = max(wordsA.count, wordsB.count)

        for i in 0..<maxCount {
            let a = i < wordsA.count ? wordsA[i] : nil
            let b = i < wordsB.count ? wordsB[i] : nil

            if a == b {
                results.append(TextDiffView.DiffLine(text: "  " + (a ?? ""), color: .secondary, bgColor: .clear, lineNumber: "\(i+1)"))
                same += 1
            } else {
                if let a {
                    results.append(TextDiffView.DiffLine(text: "- " + a, color: .red, bgColor: .red.opacity(0.08), lineNumber: "\(i+1)"))
                    dels += 1
                }
                if let b {
                    results.append(TextDiffView.DiffLine(text: "+ " + b, color: .green, bgColor: .green.opacity(0.08), lineNumber: "\(i+1)"))
                    adds += 1
                }
            }
        }
        diffLines = results
        additions = adds; deletions = dels; unchanged = same
        let total = adds + dels + same
        similarity = total > 0 ? (Double(same) / Double(total)) * 100 : 100
    }
}

#Preview {
    TextDiffView()
}
