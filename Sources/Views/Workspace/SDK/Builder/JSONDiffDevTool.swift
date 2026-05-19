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
        VStack {
            HStack {
                VStack {
                    Text("Left JSON").font(.caption.bold())
                    TextEditor(text: $viewModel.leftJSON)
                        .frame(height: 150)
                        .font(.system(.caption2, design: .monospaced))
                }
                VStack {
                    Text("Right JSON").font(.caption.bold())
                    TextEditor(text: $viewModel.rightJSON)
                        .frame(height: 150)
                        .font(.system(.caption2, design: .monospaced))
                }
            }
            .padding(.horizontal)

            Form {
                Section("Differences") {
                    if viewModel.diffResults.isEmpty {
                        Text("No differences found").foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.diffResults) { result in
                            HStack {
                                Image(systemName: result.type.icon)
                                    .foregroundStyle(result.type.color)
                                VStack(alignment: .leading) {
                                    Text(result.path).font(.caption.bold())
                                    Text(result.description).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
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
