import SwiftUI

struct DiffToolView: View {
    @State private var text1 = ""
    @State private var text2 = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Original").font(.headline)
                    TextEditor(text: $text1)
                        .font(.system(.caption, design: .monospaced))
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }

                VStack(alignment: .leading) {
                    Text("Modified").font(.headline)
                    TextEditor(text: $text2)
                        .font(.system(.caption, design: .monospaced))
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            .padding()

            Divider()

            VStack(alignment: .leading) {
                Text("Diff Comparison").font(.headline)

                // Simple line-by-line diff implementation for demonstration
                ScrollView {
                    let lines1 = text1.components(separatedBy: .newlines)
                    let lines2 = text2.components(separatedBy: .newlines)
                    let maxLines = max(lines1.count, lines2.count)

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(0..<maxLines, id: \.self) { i in
                            let l1 = i < lines1.count ? lines1[i] : nil
                            let l2 = i < lines2.count ? lines2[i] : nil

                            if l1 == l2 {
                                Text(l1 ?? "").font(.system(.caption2, design: .monospaced))
                                    .padding(.horizontal, 4)
                            } else {
                                if let val1 = l1 {
                                    Text("- \(val1)").font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.red.opacity(0.1))
                                }
                                if let val2 = l2 {
                                    Text("+ \(val2)").font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(.green)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.green.opacity(0.1))
                                }
                            }
                        }
                    }
                }
                .padding(4)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .navigationTitle("Diff Tool")
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
