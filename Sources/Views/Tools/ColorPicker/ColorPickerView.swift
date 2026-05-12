import SwiftUI

struct ColorPickerView: View {
    @StateObject private var backend = ColorPickerBackend()

    var body: some View {
        VStack(spacing: 20) {
            ColorPicker("Select Color", selection: $backend.selectedColor)
                .font(.headline)

            Rectangle()
                .fill(backend.selectedColor)
                .frame(maxWidth: .infinity, maxHeight: 200)
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
            #if canImport(UIKit)
            .background(Color(uiColor: .secondarySystemBackground))
            #else
            .background(.quaternary)
            #endif
            .cornerRadius(12)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Color Picker")
    }
}

struct ColorPickerTool: Tool, Sendable {
    let name = "Color Picker"
    let icon = "eyedropper"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "HEX and RGB Color Conversion"
    let requiresAPI = false

    var view: AnyView {
        AnyView(ColorPickerView())
    }
}
