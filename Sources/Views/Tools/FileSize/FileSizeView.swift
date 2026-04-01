import SwiftUI

@available(macOS 11.0, *)
struct FileSizeView: View {
    @StateObject private var backend = FileSizeBackend()

    var body: some View {
        Form {
            Section(header: Text("Input")) {
                TextField("Amount", text: $backend.inputAmount)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
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

@available(macOS 11.0, *)
struct FileSizeTool: Tool {
    let name = "File Size Converter"
    let icon = "externaldrive"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Convert between various file size units"

    var view: AnyView {
        AnyView(FileSizeView())
    }
}
