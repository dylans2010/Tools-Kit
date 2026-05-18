import SwiftUI

struct TextDiffDevTool: DevTool {
    let id = "text-diff"
    let name = "Text Diff"
    let category = DevToolCategory.utilities
    let icon = "rectangle.2.swap"
    let description = "Compare two text blocks for changes"

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
    }

    @StateObject private var viewModel = TextDiffViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Text Diff",
                description: "Compare two blocks of text side-by-side to visualize additions and removals.",
                icon: "rectangle.2.swap"
            )
            .padding()

            HStack {
                VStack {
                    Text("Original").font(.caption.bold())
                    TextEditor(text: $viewModel.textA)
                        .frame(height: 150)
                        .font(.system(.caption2, design: .monospaced))
                }
                VStack {
                    Text("Modified").font(.caption.bold())
                    TextEditor(text: $viewModel.textB)
                        .frame(height: 150)
                        .font(.system(.caption2, design: .monospaced))
                }
            }
            .padding(.horizontal)

            Form {
                Section("Diff Result") {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.diffLines) { (line: TextDiffView.DiffLine) in
                                Text(line.text)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(line.color)
                                    .padding(.horizontal, 4)
                                    .background(line.bgColor)
                            }
                        }
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}

class TextDiffViewModel: ObservableObject {
    @Published var textA = "Hello World\nThis is a test" {
        didSet { compare() }
    }
    @Published var textB = "Hello World\nThis is an updated test" {
        didSet { compare() }
    }
    @Published var diffLines: [TextDiffView.DiffLine] = []

    private func compare() {
        // Simple line-by-line diff
        let linesA = textA.components(separatedBy: .newlines)
        let linesB = textB.components(separatedBy: .newlines)

        var results: [TextDiffView.DiffLine] = []
        let maxCount = max(linesA.count, linesB.count)

        for i in 0..<maxCount {
            let a = i < linesA.count ? linesA[i] : nil
            let b = i < linesB.count ? linesB[i] : nil

            if a == b {
                results.append(TextDiffView.DiffLine(text: "  " + (a ?? ""), color: .secondary, bgColor: .clear))
            } else {
                if let a = a {
                    results.append(TextDiffView.DiffLine(text: "- " + a, color: .red, bgColor: .red.opacity(0.1)))
                }
                if let b = b {
                    results.append(TextDiffView.DiffLine(text: "+ " + b, color: .green, bgColor: .green.opacity(0.1)))
                }
            }
        }
        diffLines = results
    }
}
