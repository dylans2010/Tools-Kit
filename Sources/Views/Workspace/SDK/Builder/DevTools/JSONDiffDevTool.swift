import SwiftUI

struct JSONDiffTool: DevTool {
    let id = UUID()
    let name = "JSON Diff"
    let category: DevToolCategory = .data
    let icon = "arrow.left.arrow.right.square"
    let description = "Compare two JSON documents"
    func render() -> some View { JSONDiffDevToolView() }
}

struct JSONDiffDevToolView: View {
    @State private var left = ""
    @State private var right = ""
    @State private var diffs: [(String, String, String)] = []
    @State private var errorMsg: String?
    var body: some View {
        Form {
            Section("JSON A") {
                TextEditor(text: $left).frame(minHeight: 80).font(.system(.caption, design: .monospaced))
            }
            Section("JSON B") {
                TextEditor(text: $right).frame(minHeight: 80).font(.system(.caption, design: .monospaced))
            }
            Section {
                Button("Compare") { compare() }
                    .disabled(left.isEmpty || right.isEmpty)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if !diffs.isEmpty {
                Section("Differences (\(diffs.count))") {
                    ForEach(Array(diffs.enumerated()), id: \.offset) { _, diff in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(diff.0).font(.caption.bold()).foregroundStyle(.accent)
                            HStack {
                                Text("A: \(diff.1)").font(.system(.caption2, design: .monospaced)).foregroundStyle(.red)
                                Spacer()
                                Text("B: \(diff.2)").font(.system(.caption2, design: .monospaced)).foregroundStyle(.green)
                            }
                        }
                    }
                }
            } else if errorMsg == nil && !left.isEmpty && !right.isEmpty {
                Section { Label("Documents are identical", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
            }
        }
        .navigationTitle("JSON Diff")
    }
    private func compare() {
        errorMsg = nil; diffs.removeAll()
        guard let d1 = left.data(using: .utf8), let d2 = right.data(using: .utf8),
              let o1 = try? JSONSerialization.jsonObject(with: d1) as? [String: Any],
              let o2 = try? JSONSerialization.jsonObject(with: d2) as? [String: Any] else {
            errorMsg = "Both inputs must be valid JSON objects"; return
        }
        let allKeys = Set(o1.keys).union(o2.keys).sorted()
        for key in allKeys {
            let v1 = o1[key].map { "\($0)" } ?? "(missing)"
            let v2 = o2[key].map { "\($0)" } ?? "(missing)"
            if v1 != v2 { diffs.append((key, v1, v2)) }
        }
    }
}
