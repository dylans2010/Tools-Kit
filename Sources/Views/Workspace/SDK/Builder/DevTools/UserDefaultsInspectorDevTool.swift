import SwiftUI

struct UserDefaultsInspectorTool: DevTool {
    let id = UUID()
    let name = "UserDefaults Inspector"
    let category: DevToolCategory = .storage
    let icon = "list.bullet.rectangle.portrait"
    let description = "Browse and edit UserDefaults"
    func render() -> some View { UserDefaultsInspectorDevToolView() }
}

struct UserDefaultsInspectorDevToolView: View {
    @State private var entries: [(String, String, String)] = []
    @State private var searchText = ""

    private var filtered: [(String, String, String)] {
        if searchText.isEmpty { return entries }
        return entries.filter { $0.0.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        Form {
            Section {
                Button("Refresh") { loadDefaults() }
                Text("\(entries.count) entries").font(.caption).foregroundStyle(.secondary)
            }
            Section("UserDefaults (\(filtered.count))") {
                ForEach(Array(filtered.enumerated()), id: \.offset) { _, entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.0).font(.caption.bold())
                        HStack {
                            Text(entry.1)
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        Text(entry.2)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search keys...")
        .navigationTitle("UserDefaults Inspector")
        .onAppear { loadDefaults() }
    }

    private func loadDefaults() {
        let dict = UserDefaults.standard.dictionaryRepresentation()
        entries = dict.map { key, value in
            let typeStr: String
            switch value {
            case is String: typeStr = "String"
            case is Int: typeStr = "Int"
            case is Double: typeStr = "Double"
            case is Bool: typeStr = "Bool"
            case is Data: typeStr = "Data"
            case is [Any]: typeStr = "Array"
            case is [String: Any]: typeStr = "Dictionary"
            default: typeStr = String(describing: type(of: value))
            }
            return (key, typeStr, String(describing: value).prefix(200).description)
        }.sorted { $0.0 < $1.0 }
    }
}
