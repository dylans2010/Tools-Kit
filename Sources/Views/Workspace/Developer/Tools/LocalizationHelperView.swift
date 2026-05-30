import SwiftUI

struct LocalizationHelperView: View {
    @State private var keys: [LocKey] = [
        LocKey(key: "common_save", value: "Save"),
        LocKey(key: "common_cancel", value: "Cancel")
    ]

    struct LocKey: Identifiable {
        let id = UUID()
        var key: String
        var value: String
    }

    var body: some View {
        List {
            Section {
                Button {
                    keys.append(LocKey(key: "", value: ""))
                } label: {
                    Label("Add Localization Key", systemImage: "plus")
                }
            }

            Section("Localizable.strings Preview") {
                Text(generateStrings())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }

            Section("Editor") {
                ForEach($keys) { $item in
                    VStack(alignment: .leading) {
                        TextField("Key", text: $item.key)
                            .font(.caption.bold())
                            .autocorrectionDisabled()
                            .autocapitalization(.none)

                        TextField("Value", text: $item.value)
                            .font(.subheadline)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            keys.removeAll { $0.id == item.id }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Localization Helper")
    }

    private func generateStrings() -> String {
        keys.map { "\"\($0.key)\" = \"\($0.value)\";" }.joined(separator: "\n")
    }
}
