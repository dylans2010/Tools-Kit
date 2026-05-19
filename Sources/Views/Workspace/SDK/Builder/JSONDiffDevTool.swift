import SwiftUI

struct JSONDiffDevTool: DevTool {
    let id = "json-diff"
    let name = "JSON Diff"
    let category = DevToolCategory.data
    let icon = "square.split.2x1"
    let description = "Compare two JSON objects"

    func render() -> some View {
        JSONDiffView()
    }
}

struct JSONDiffView: View {
    @StateObject private var viewModel = JSONDiffViewModel()

    var body: some View {
        List {
            Section("Comparison Source") {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("Source A").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                            TextEditor(text: $viewModel.leftJSON)
                                .frame(height: 120)
                                .font(.system(size: 9, design: .monospaced))
                                .padding(4)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading) {
                            Text("Source B").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                            TextEditor(text: $viewModel.rightJSON)
                                .frame(height: 120)
                                .font(.system(size: 9, design: .monospaced))
                                .padding(4)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                    }

                    Button { viewModel.swap() } label: {
                        Label("Swap Sources", systemImage: "arrow.left.and.right")
                            .font(.caption2.bold())
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Deltas Found (\(viewModel.diffResults.count))") {
                if viewModel.diffResults.isEmpty {
                    ContentUnavailableView("Identical Objects", systemImage: "equal.circle", description: Text("No structural or value differences detected between inputs."))
                } else {
                    ForEach(viewModel.diffResults) { result in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: result.type.icon)
                                .foregroundStyle(result.type.color)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.path).font(.system(size: 11, weight: .bold, design: .monospaced))
                                Text(result.description).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Button("Format Both Inputs") { viewModel.formatBoth() }
                Button("Clear All") { viewModel.leftJSON = ""; viewModel.rightJSON = "" }
            }
        }
        .navigationTitle("JSON Diff")
    }
}

enum JSONDiffType {
    case added, deleted, modified

    var icon: String {
        switch self {
        case .added: return "plus.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .modified: return "pencil.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .added: return .green
        case .deleted: return .red
        case .modified: return .orange
        }
    }
}

struct JSONDiffResult: Identifiable {
    let id = UUID()
    let path: String
    let description: String
    let type: JSONDiffType
}

class JSONDiffViewModel: ObservableObject {
    @Published var leftJSON = "{\"id\": 1, \"name\": \"Original\"}" {
        didSet { compare() }
    }
    @Published var rightJSON = "{\"id\": 1, \"name\": \"Updated\", \"status\": \"active\"}" {
        didSet { compare() }
    }
    @Published var diffResults: [JSONDiffResult] = []

    func swap() {
        let temp = leftJSON
        leftJSON = rightJSON
        rightJSON = temp
    }

    func formatBoth() {
        leftJSON = format(leftJSON)
        rightJSON = format(rightJSON)
    }

    private func format(_ s: String) -> String {
        guard let data = s.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else { return s }
        return String(data: pretty, encoding: .utf8) ?? s
    }

    private func compare() {
        guard let leftData = leftJSON.data(using: .utf8),
              let leftObj = try? JSONSerialization.jsonObject(with: leftData) as? [String: Any],
              let rightData = rightJSON.data(using: .utf8),
              let rightObj = try? JSONSerialization.jsonObject(with: rightData) as? [String: Any] else {
            return
        }

        var results: [JSONDiffResult] = []

        // Check for deletions and modifications
        for (key, leftVal) in leftObj {
            if let rightVal = rightObj[key] {
                if String(describing: leftVal) != String(describing: rightVal) {
                    results.append(JSONDiffResult(path: key, description: "Changed: \(leftVal) -> \(rightVal)", type: .modified))
                }
            } else {
                results.append(JSONDiffResult(path: key, description: "Deleted key", type: .deleted))
            }
        }

        // Check for additions
        for (key, _) in rightObj {
            if leftObj[key] == nil {
                results.append(JSONDiffResult(path: key, description: "Added key", type: .added))
            }
        }

        diffResults = results
    }
}

#Preview {
    JSONDiffView()
}
