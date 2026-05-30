import SwiftUI

struct HTMLInspectorView: View {
    @State private var htmlInput = "<div>\n  <h1>Title</h1>\n  <p>Hello World</p>\n</div>"

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("HTML Source").font(.headline)
                TextEditor(text: $htmlInput)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 200)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Tag Tree (Simulated)").font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        // Very basic tag highlighter for demonstration
                        let tags = htmlInput.components(separatedBy: "<")
                        ForEach(Array(tags.enumerated()), id: \.offset) { _, part in
                            if let endBracket = part.firstIndex(of: ">") {
                                let tagName = part[..<endBracket]
                                let rest = part[part.index(after: endBracket)...]

                                HStack(spacing: 0) {
                                    Text("<").foregroundStyle(.secondary)
                                    Text(String(tagName)).foregroundStyle(.blue).bold()
                                    Text(">").foregroundStyle(.secondary)
                                    Text(String(rest))
                                }
                                .font(.system(.caption, design: .monospaced))
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .navigationTitle("HTML Inspector")
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
