import SwiftUI

struct SDKUIScreenEditorView: View {
    @State private var screenTitle: String = "New Screen"
    @State private var elements: [SDKUIElement] = []

    var body: some View {
        Form {
            Section("Screen Metadata") {
                TextField("Title", text: $screenTitle)
            }

            Section("UI Elements") {
                List {
                    ForEach(elements) { element in
                        Text(String(describing: element.type))
                    }
                    .onDelete { elements.remove(atOffsets: $0) }
                }

                Menu("Add Element") {
                    Button("Text") { addElement(.text("New Text")) }
                    Button("Button") { addElement(.button(label: "Click Me", actionID: "custom_action")) }
                    Button("Data List") { addElement(.list(.tasks)) }
                }
            }
        }
        .navigationTitle("Screen Editor")
    }

    private func addElement(_ type: SDKUIElementType) {
        elements.append(SDKUIElement(id: UUID(), type: type))
    }
}
