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
        Form {
            Section(header: Text("Input Text")) {
                TextField("Enter characters...", text: $viewModel.input)
            }

            if !viewModel.characters.isEmpty {
                Section(header: Text("Analysis")) {
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
                                Text(item.category)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .foregroundStyle(.white)
                                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .padding(.vertical, 4)
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

#Preview {
    UnicodeInspectorView()
}
