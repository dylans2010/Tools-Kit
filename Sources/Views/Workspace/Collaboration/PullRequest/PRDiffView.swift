import SwiftUI

struct PRDiffView: View {
    let prID: UUID

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Changes in PR \(prID.uuidString.prefix(8))")
                    .font(.headline)
                    .padding()

                // Simulated Side-by-Side Diff
                HStack(spacing: 0) {
                    DiffColumn(title: "Original", content: "Original content of the object...", color: .red.opacity(0.1))
                    Divider()
                    DiffColumn(title: "Proposed", content: "Updated content with new changes and improvements...", color: .green.opacity(0.1))
                }
                .frame(height: 400)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.3)))
                .padding()

                VStack(alignment: .leading) {
                    Text("Inline Comments")
                        .font(.subheadline)
                        .bold()

                    CommentThreadView()
                }
                .padding()
            }
        }
        .navigationTitle("Side-by-Side Diff")
    }
}

struct DiffColumn: View {
    let title: String
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .bold()
                .padding(4)
                .background(Color.secondary.opacity(0.2))

            Text(content)
                .font(.system(.body, design: .monospaced))
                .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color)
    }
}

struct CommentThreadView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(Color.blue).frame(width: 30, height: 30)
                Text("Reviewer Alpha")
                    .font(.footnote)
                    .bold()
                Text("2 hours ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text("Should we reconsider the layout of this section for better accessibility?")
                .font(.subheadline)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
    }
}
