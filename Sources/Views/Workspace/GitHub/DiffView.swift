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
