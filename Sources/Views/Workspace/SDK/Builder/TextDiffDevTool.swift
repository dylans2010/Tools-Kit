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
    @StateObject private var viewModel = TextDiffViewModel()
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            editorSection

            summaryBar

            diffResultSection
        }
        .navigationTitle("Text Diff")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.swapTexts()
                } label: {
                    Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.clear()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private var editorSection: some View {
        HStack(spacing: 1) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ORIGINAL").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).padding(.leading, 8)
                TextEditor(text: $viewModel.textA)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(4)
                    .background(Color(.secondarySystemBackground))
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("MODIFIED").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).padding(.leading, 8)
                TextEditor(text: $viewModel.textB)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(4)
                    .background(Color(.secondarySystemBackground))
            }
        }
        .frame(height: 200)
        .background(Color(.systemBackground))
    }

    private var summaryBar: some View {
        HStack {
            HStack(spacing: 12) {
                Label("\(viewModel.additions) additions", systemImage: "plus.circle.fill")
                    .foregroundStyle(.green)
                Label("\(viewModel.deletions) deletions", systemImage: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .font(.system(size: 10, weight: .bold))

            Spacer()

            Picker("View", selection: $viewModel.diffMode) {
                Text("Unified").tag(DiffViewMode.unified)
                Text("Split").tag(DiffViewMode.split)
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
    }

    private var diffResultSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.diffLines.isEmpty {
                    ContentUnavailableView("No Differences", systemImage: "equal.square", description: Text("The texts are identical."))
                        .padding(.top, 40)
                } else {
                    ForEach(viewModel.diffLines) { line in
                        DiffLineRow(line: line)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemBackground))
    }
}

enum DiffViewMode {
    case unified, split
}

struct DiffLineRow: View {
    let line: DiffLine

    var body: some View {
        HStack(spacing: 0) {
            Text(line.prefix)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(line.color.opacity(0.8))
                .frame(width: 24, alignment: .center)
                .background(line.bgColor.opacity(0.5))

            Text(line.text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(line.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(line.bgColor)
        }
        .overlay(alignment: .bottom) {
            Divider().opacity(0.05)
        }
    }
}

struct DiffLine: Identifiable {
    let id = UUID()
    let text: String
    let prefix: String
    let color: Color
    let bgColor: Color
    let type: DiffType
}

enum DiffType {
    case added, removed, unchanged
}

class TextDiffViewModel: ObservableObject {
    @Published var textA = "{\n  \"name\": \"ToolsKit\",\n  \"version\": \"2.3\",\n  \"active\": true\n}" {
        didSet { compare() }
    }
    @Published var textB = "{\n  \"name\": \"ToolsKit SDK\",\n  \"version\": \"2.4\",\n  \"active\": true,\n  \"platform\": \"iOS\"\n}" {
        didSet { compare() }
    }
    @Published var diffLines: [DiffLine] = []
    @Published var diffMode: DiffViewMode = .unified

    @Published var additions = 0
    @Published var deletions = 0

    init() {
        compare()
    }

    func swapTexts() {
        let temp = textA
        textA = textB
        textB = temp
    }

    func clear() {
        textA = ""
        textB = ""
    }

    private func compare() {
        let linesA = textA.components(separatedBy: .newlines)
        let linesB = textB.components(separatedBy: .newlines)

        var results: [DiffLine] = []
        var adds = 0
        var dels = 0

        // Simple Myers-ish approximation for UI tool
        let maxCount = max(linesA.count, linesB.count)

        for i in 0..<maxCount {
            let a = i < linesA.count ? linesA[i] : nil
            let b = i < linesB.count ? linesB[i] : nil

            if a == b {
                if let val = a {
                    results.append(DiffLine(text: val, prefix: " ", color: .primary, bgColor: .clear, type: .unchanged))
                }
            } else {
                if let valA = a {
                    results.append(DiffLine(text: valA, prefix: "-", color: .red, bgColor: .red.opacity(0.1), type: .removed))
                    dels += 1
                }
                if let valB = b {
                    results.append(DiffLine(text: valB, prefix: "+", color: .green, bgColor: .green.opacity(0.1), type: .added))
                    adds += 1
                }
            }
        }

        self.diffLines = results
        self.additions = adds
        self.deletions = dels
    }
}

#Preview {
    TextDiffView()
}
