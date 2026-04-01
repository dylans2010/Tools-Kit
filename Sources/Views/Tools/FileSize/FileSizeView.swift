import SwiftUI

struct FileSizeView: View {
    @StateObject private var backend = FileSizeBackend()

    var body: some View {
        Form {
            Section(header: Text("Input")) {
                TextField("Amount", text: $backend.inputAmount)
                    .keyboardType(.decimalPad)
                Picker("Unit", selection: $backend.inputUnit) {
                    ForEach(FileSizeBackend.SizeUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
            }

            Section(header: Text("Conversion Results")) {
                Text(backend.result)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }

            Button("Convert") {
                backend.convert()
            }
        }
        .navigationTitle("File Size Converter")
    }
}

struct FileSizeTool: Tool {
    let name = "File Size Converter"
    let icon = "externaldrive"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Convert between various file size units"
    let requiresAPI = false

    var view: AnyView {
        AnyView(FileSizeView())
    }
}
