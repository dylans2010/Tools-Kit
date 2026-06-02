import SwiftUI

struct UnitConverterDevTool: DevTool {
    let id = "unit-converter"
    let name = "Unit Converter"
    let category: DevToolCategory = .utilities
    let icon = "scalemass"
    let description = "Convert between various physical units (length, weight, etc.)"

    func render() -> some View {
        UnitConverterDevToolView()
    }
}

struct UnitConverterDevToolView: View {
    @State private var value: Double = 1.0
    @State private var result = ""

    var body: some View {
        Form {
            Section("Value") {
                TextField("Enter value", value: $value, format: .number)
            }
            Button("Convert (km to miles)") {
                result = "\(value) km = \(value * 0.621371) miles"
            }
            .frame(maxWidth: .infinity)

            if !result.isEmpty {
                Section("Result") {
                    Text(result)
                }
            }
        }
    }
}
