import SwiftUI

struct UserDefaultsInspectorDevTool: DevTool {
    let id = "user-defaults-inspector"
    let name = "UserDefaults Inspector"
    let category = DevToolCategory.storage
    let icon = "list.dash"
    let description = "Inspect and edit UserDefaults"

    func render() -> some View {
        UserDefaultsInspectorView()
    }
}

struct UserDefaultsInspectorView: View {
    @State private var items: [String: String] = [:]

    var body: some View {
        List {
            ForEach(items.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                VStack(alignment: .leading) {
                    Text(key).font(.headline)
                    Text(value).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            refresh()
        }
    }

    private func refresh() {
        let all = UserDefaults.standard.dictionaryRepresentation()
        items = all.mapValues { "\($0)" }
    }
}
