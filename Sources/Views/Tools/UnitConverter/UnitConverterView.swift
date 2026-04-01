import SwiftUI

@available(macOS 11.0, *)
struct UnitConverterView: View {
    @StateObject private var backend = UnitConverterBackend()

    var body: some View {
        Form {
            Section(header: Text("Input")) {
                TextField("Amount", text: $backend.input)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                Picker("From", selection: $backend.inputUnit) {
                    ForEach(backend.units, id: \.self) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                }
            }

            Section(header: Text("Output")) {
                Picker("To", selection: $backend.outputUnit) {
                    ForEach(backend.units, id: \.self) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                }
                Text(backend.output)
                    .font(.headline)
            }

            Button("Convert") {
                backend.convert()
            }
        }
        .navigationTitle("Unit Converter")
    }
}

@available(macOS 11.0, *)
struct UnitConverterTool: Tool {
    let name = "Unit Converter"
    let icon = "ruler"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Convert between various measurement units"

    var view: AnyView {
        AnyView(UnitConverterView())
    }
}
