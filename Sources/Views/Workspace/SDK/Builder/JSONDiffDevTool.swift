import SwiftUI

struct JSONDiffDevTool: DevTool {
    let id = "json-diff"
    let name = "JSON Diff"
    let category = DevToolCategory.data
    let icon = "arrow.left.arrow.right"
    let description = "Compare two JSON objects"

    func render() -> some View {
        JSONDiffView()
    }
}

struct JSONDiffView: View {
    @StateObject private var viewModel = JSONDiffViewModel()

    var body: some View {
        Form {
            Section("JSON A") {
                TextEditor(text: $viewModel.jsonA)
                    .frame(height: 120)
                    .font(.monospaced(.body)())
            }

            Section("JSON B") {
                TextEditor(text: $viewModel.jsonB)
                    .frame(height: 120)
                    .font(.monospaced(.body)())
            }

            Section("Diff Result") {
                if viewModel.isEqual {
                    Label("Objects are identical", systemImage: "equal")
                        .foregroundStyle(.green)
                } else {
                    Label("Objects differ", systemImage: "not.equal")
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

class JSONDiffViewModel: ObservableObject {
    @Published var jsonA = ""
    @Published var jsonB = ""

    var isEqual: Bool {
        guard let dataA = jsonA.data(using: .utf8),
              let dataB = jsonB.data(using: .utf8),
              let objA = try? JSONSerialization.jsonObject(with: dataA) as? NSDictionary,
              let objB = try? JSONSerialization.jsonObject(with: dataB) as? NSDictionary else {
            return false
        }
        return objA.isEqual(to: objB as! [AnyHashable : Any])
    }
}
