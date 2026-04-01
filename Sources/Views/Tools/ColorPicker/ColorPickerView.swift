import SwiftUI

@available(macOS 11.0, *)
struct ColorPickerView: View {
    @StateObject private var backend = ColorPickerBackend()

    var body: some View {
        VStack(spacing: 20) {
            ColorPicker("Select a Color", selection: $backend.selectedColor)
                .font(.headline)
                .padding()

            Rectangle()
                .fill(backend.selectedColor)
                .frame(width: 200, height: 100)
                .cornerRadius(12)
                .shadow(radius: 5)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("HEX:")
                    Spacer()
                    Text(backend.hex)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("RGB:")
                    Spacer()
                    Text(backend.rgb)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            Spacer()
        }
        .padding()
        .navigationTitle("Color Picker")
    }
}

@available(macOS 11.0, *)
struct ColorPickerTool: Tool {
    let name = "Color Picker"
    let icon = "eyedropper"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "HEX and RGB color conversion"

    var view: AnyView {
        AnyView(ColorPickerView())
    }
}
