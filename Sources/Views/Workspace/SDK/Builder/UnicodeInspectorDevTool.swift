import SwiftUI

struct UnicodeInspectorDevTool: DevTool {
    let id = "unicode-inspector"
    let name = "Unicode Inspector"
    let category = DevToolCategory.encoding
    let icon = "character.cursor.ibeam"
    let description = "Inspect Unicode properties of characters"

    func render() -> some View {
        UnicodeInspectorView()
    }
}

struct UnicodeInspectorView: View {
    @StateObject private var viewModel = UnicodeInspectorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Unicode Inspector",
                description: "Deep dive into character properties, including scalar values, categories, and encoding blocks.",
                icon: "character.cursor.ibeam"
            )
            .padding()

            Form {
                Section("Input Text") {
                    TextField("Enter characters...", text: $viewModel.input)
                }

                if !viewModel.characters.isEmpty {
                    Section("Analysis") {
                        ForEach(viewModel.characters) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.character)
                                        .font(.title2)
                                        .frame(width: 40)
                                    VStack(alignment: .leading) {
                                        Text(item.name).font(.caption.bold())
                                        Text("U+\(item.scalar)").font(.caption2.monospaced())
                                    }
                                    Spacer()
                                    StatusBadge(text: item.category, color: .accentColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
}

struct UnicodeItem: Identifiable {
    let id = UUID()
    let character: String
    let scalar: String
    let name: String
    let category: String
}

class UnicodeInspectorViewModel: ObservableObject {
    @Published var input = "Hello 🌍" {
        didSet {
            inspect()
        }
    }
    @Published var characters: [UnicodeItem] = []

    private func inspect() {
        characters = input.map { char in
            let scalars = char.unicodeScalars
            let scalar = scalars.first!
            return UnicodeItem(
                character: String(char),
                scalar: String(format: "%04X", scalar.value),
                name: scalar.properties.name ?? "Unnamed Character",
                category: "\(scalar.properties.generalCategory)"
            )
        }
    }
}
