import SwiftUI

/// Shows diff for files in a PR or comparison.
struct DiffView: View {
    let fileDiff: GitHubFileDiff

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(fileDiff.filename)
                    .font(.caption.bold())
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))

                if let patch = fileDiff.patch {
                    ForEach(patch.components(separatedBy: .newlines), id: \.self) { line in
                        lineView(for: line)
                    }
                } else {
                    Text("No patch available (binary or too large).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .navigationTitle("Diff")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Convenience initializer that generates a unified patch from raw original/modified strings.
    init(original: String, modified: String, filename: String = "Untitled") {
        let patch = Self.generatePatch(original: original, modified: modified)
        self.fileDiff = GitHubFileDiff(
            sha: "",
            filename: filename,
            status: "modified",
            additions: 0,
            deletions: 0,
            changes: 0,
            patch: patch.isEmpty ? nil : patch
        )
    }

    private static func generatePatch(original: String, modified: String) -> String {
        guard original != modified else { return "" }
        let oldLines = original.components(separatedBy: "\n")
        let newLines = modified.components(separatedBy: "\n")
        var lines: [String] = []
        lines.reserveCapacity(oldLines.count + newLines.count + 1)
        lines.append("@@ -1,\(oldLines.count) +1,\(newLines.count) @@")
        for line in oldLines { lines.append("-\(line)") }
        for line in newLines { lines.append("+\(line)") }
        return lines.joined(separator: "\n")
    }

    @ViewBuilder
    private func lineView(for line: String) -> some View {
        let color: Color = {
            if line.hasPrefix("+") { return Color.green.opacity(0.15) }
            if line.hasPrefix("-") { return Color.red.opacity(0.15) }
            if line.hasPrefix("@@") { return Color.blue.opacity(0.1) }
            return .clear
        }()

        Text(line)
            .font(.system(.caption2, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .background(color)
    }
}
