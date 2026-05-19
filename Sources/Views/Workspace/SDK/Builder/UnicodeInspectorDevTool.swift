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
        List {
            Section("Character Stream") {
                TextField("Enter characters (emojis supported)...", text: $viewModel.input)
                    .font(.title3)
                    .padding(.vertical, 4)

                HStack {
                    Text("\(viewModel.input.count) characters").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear") { viewModel.input = "" }.font(.caption2)
                }
            }

            Section("Scalar Properties") {
                if viewModel.characters.isEmpty {
                    ContentUnavailableView("Enter Text", systemImage: "character.cursor.ibeam", description: Text("Input characters to see their Unicode properties."))
                } else {
                    ForEach(viewModel.characters) { item in
                        HStack(spacing: 16) {
                            Text(item.character)
                                .font(.system(size: 32))
                                .frame(width: 50, height: 50)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline.bold())
                                    .lineLimit(1)

                                HStack(spacing: 8) {
                                    Text("U+\(item.scalar)").font(.system(size: 10, design: .monospaced)).foregroundStyle(.blue)
                                    Text(item.category).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
                                }
                            }

                            Spacer()

                            Button { UIPasteboard.general.string = "U+\(item.scalar)" } label: {
                                Image(systemName: "doc.on.doc").font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Unicode Lab")
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
