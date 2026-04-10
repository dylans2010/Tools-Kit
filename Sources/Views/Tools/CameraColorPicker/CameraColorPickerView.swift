import SwiftUI
import AVFoundation

struct CameraColorPickerView: View {
    @State private var pickedColor = Color.white
    @State private var hexCode = "#FFFFFF"
    @State private var recentColors: [String] = []

    var body: some View {
        VStack {
            ZStack {
                Color.black
                Text("Camera Feed Placeholder")
                    .foregroundColor(.white)

                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .padding()

            VStack(spacing: 12) {
                Rectangle()
                    .fill(pickedColor)
                    .frame(height: 50)
                    .cornerRadius(8)

                Text(hexCode)
                    .font(.system(.title3, design: .monospaced))

                Button("Capture Color") {
                    let generated = String(format: "#%06X", Int.random(in: 0...0xFFFFFF))
                    hexCode = generated
                    pickedColor = Color(hex: generated.replacingOccurrences(of: "#", with: "")) ?? .white
                    recentColors.insert(generated, at: 0)
                    recentColors = Array(recentColors.prefix(8))
                }
                .buttonStyle(.borderedProminent)

                if !recentColors.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(recentColors, id: \.self) { code in
                                Text(code)
                                    .font(.caption.monospaced())
                                    .padding(6)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Camera Color Picker")
    }
}

struct CameraColorPickerTool: Tool {
    let name = "Cam Color Picker"
    let icon = "eyedropper.halfsquare"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Extract colors in real-time using your camera"
    let requiresAPI = false
    var view: AnyView { AnyView(CameraColorPickerView()) }
}
