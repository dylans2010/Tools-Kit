import SwiftUI

struct UnicodeInspectorDevTool: DevTool {
    let id = "unicode-inspector"
    let name = "Unicode Inspector"
    let category = DevToolCategory.inputOutput
    let icon = "character.cursor.ibeam"
    let description = "Inspect Unicode characters"

    func render() -> some View {
        UnicodeInspectorView()
    }
}

struct UnicodeInspectorView: View {
    @StateObject private var viewModel = UnicodeInspectorViewModel()

    var body: some View {
        Form {
            Section("Input Text") {
                TextField("Type characters here...", text: $viewModel.inputText)
            }

            Section("Characters") {
                ForEach(viewModel.characters, id: \.index) { info in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(info.char).font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text("U+\(info.codePoint)")
                                    .font(.monospaced(.body)())
                                Text(info.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CharInfo {
    let index: Int
    let char: String
    let codePoint: String
    let name: String
}

class UnicodeInspectorViewModel: ObservableObject {
    @Published var inputText = ""

    var characters: [CharInfo] {
        inputText.enumerated().map { index, char in
            let codePoint = String(format: "%04X", char.unicodeScalars.first?.value ?? 0)
            return CharInfo(
                index: index,
                char: String(char),
                codePoint: codePoint,
                name: ""
            )
        }
    }
}
