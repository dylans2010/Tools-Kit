import SwiftUI

struct DiffMatchPatchDevTool: DevTool {
    let id = "diff-match-patch"
    let name = "Diff Match Patch Tool"
    let category: DevToolCategory = .utilities
    let icon = "arrow.left.arrow.right"
    let description = "Compare two blocks of text and show line-by-line differences"

    func render() -> some View {
        DiffMatchPatchView()
    }
}

struct DiffMatchPatchView: View {
    @State private var text1 = ""
    @State private var text2 = ""
    @State private var result = ""

    var body: some View {
        Form {
            Section("Original") {
                TextEditor(text: $text1).frame(height: 100)
            }
            Section("Modified") {
                TextEditor(text: $text2).frame(height: 100)
            }
            Button("Compare") {
                compare()
            }
            .frame(maxWidth: .infinity)

            if !result.isEmpty {
                Section("Diff Result") {
                    Text(result)
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
    }

    private func compare() {
        let lines1 = text1.components(separatedBy: "\n")
        let lines2 = text2.components(separatedBy: "\n")
        var diff = ""
        for i in 0..<max(lines1.count, lines2.count) {
            let l1 = i < lines1.count ? lines1[i] : ""
            let l2 = i < lines2.count ? lines2[i] : ""
            if l1 == l2 {
                diff += "  \(l1)\n"
            } else {
                if !l1.isEmpty { diff += "- \(l1)\n" }
                if !l2.isEmpty { diff += "+ \(l2)\n" }
            }
        }
        result = diff
    }
}
