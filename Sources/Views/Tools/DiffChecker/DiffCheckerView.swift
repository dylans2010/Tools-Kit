import SwiftUI

struct DiffCheckerView: View {
    @StateObject private var backend = DiffCheckerBackend()

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Original").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $backend.text1)
                        .frame(maxHeight: 200)
                        .border(Color.gray.opacity(0.2))
                }
                VStack(alignment: .leading) {
                    Text("Modified").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $backend.text2)
                        .frame(maxHeight: 200)
                        .border(Color.gray.opacity(0.2))
                }
            }

            Button(action: { backend.check() }) {
                Text("Compare Text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if !backend.diffResults.isEmpty {
                HStack {
                    Label("\(backend.diffResults.filter { if case .added = $0 { return true } else { return false } }.count)", systemImage: "plus.circle.fill")
                        .foregroundColor(.green)
                    Label("\(backend.diffResults.filter { if case .removed = $0 { return true } else { return false } }.count)", systemImage: "minus.circle.fill")
                        .foregroundColor(.red)
                    Spacer()
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(0..<backend.diffResults.count, id: \.self) { index in
                            diffRow(for: backend.diffResults[index])
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            } else {
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Diff Checker")
    }

    @ViewBuilder
    private func diffRow(for element: DiffElement) -> some View {
        switch element {
        case .common(let text):
            Text(text)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 4)
        case .added(let text):
            Text("+ " + text)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
        case .removed(let text):
            Text("- " + text)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
        }
    }
}

struct DiffCheckerTool: Tool, Sendable {
    let name = "Diff Checker"
    let icon = "arrow.left.arrow.right"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Compare text"
    let requiresAPI = false
    var view: AnyView { AnyView(DiffCheckerView()) }
}
