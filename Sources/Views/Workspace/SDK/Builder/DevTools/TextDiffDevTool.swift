import SwiftUI

struct TextDiffTool: DevTool {
    let id = UUID()
    let name = "Text Diff"
    let category: DevToolCategory = .utilities
    let icon = "arrow.triangle.swap"
    let description = "Compare two text blocks line by line"
    func render() -> some View { TextDiffDevToolView() }
}

struct TextDiffDevToolView: View {
    @State private var textA = ""
    @State private var textB = ""
    @State private var diffs: [(String, DiffType)] = []

    enum DiffType { case same, added, removed }

    var body: some View {
        Form {
            Section("Text A") {
                TextEditor(text: $textA).frame(minHeight: 80).font(.system(.caption, design: .monospaced))
            }
            Section("Text B") {
                TextEditor(text: $textB).frame(minHeight: 80).font(.system(.caption, design: .monospaced))
            }
            Section {
                Button("Compare") { compare() }
                    .disabled(textA.isEmpty && textB.isEmpty)
            }
            if !diffs.isEmpty {
                Section("Diff (\(diffs.filter { $0.1 != .same }.count) changes)") {
                    ForEach(Array(diffs.enumerated()), id: \.offset) { _, diff in
                        HStack(spacing: 8) {
                            Text(diffPrefix(diff.1))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(diffColor(diff.1))
                                .frame(width: 16)
                            Text(diff.0)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(diffColor(diff.1))
                        }
                        .listRowBackground(diffBg(diff.1))
                    }
                }
            }
        }
        .navigationTitle("Text Diff")
    }

    private func compare() {
        let linesA = textA.components(separatedBy: .newlines)
        let linesB = textB.components(separatedBy: .newlines)
        diffs.removeAll()
        let maxLen = max(linesA.count, linesB.count)
        for i in 0..<maxLen {
            let a = i < linesA.count ? linesA[i] : nil
            let b = i < linesB.count ? linesB[i] : nil
            if a == b {
                diffs.append((a ?? "", .same))
            } else {
                if let a { diffs.append((a, .removed)) }
                if let b { diffs.append((b, .added)) }
            }
        }
    }

    private func diffPrefix(_ type: DiffType) -> String {
        switch type { case .same: return " "; case .added: return "+"; case .removed: return "-" }
    }
    private func diffColor(_ type: DiffType) -> Color {
        switch type { case .same: return .primary; case .added: return .green; case .removed: return .red }
    }
    private func diffBg(_ type: DiffType) -> Color {
        switch type { case .same: return .clear; case .added: return .green.opacity(0.05); case .removed: return .red.opacity(0.05) }
    }
}
