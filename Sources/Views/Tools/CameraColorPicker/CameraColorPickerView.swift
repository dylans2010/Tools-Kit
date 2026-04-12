import SwiftUI

struct CameraColorPickerView: View {
    @StateObject private var backend = CameraColorPickerBackend()
    @StateObject private var cameraService = CameraService()

    var body: some View {
        ToolDetailView(tool: CameraColorPickerTool()) {
            VStack(spacing: 24) {
                ZStack {
                    CameraPreview(cameraService: cameraService)
                        .onAppear {
                            cameraService.delegate = backend
                            cameraService.startSession()
                        }
                        .onDisappear {
                            cameraService.stopSession()
                        }
                        .frame(height: 400)
                        .cornerRadius(20)

                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .shadow(radius: 5)
                }

                ToolOutputView("Selected Color", value: backend.hexValue)

                RoundedRectangle(cornerRadius: 12)
                    .fill(backend.selectedColor)
                    .frame(height: 60)

                if !backend.history.isEmpty {
                    ToolInputSection("History") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(backend.history, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct CameraColorPickerTool: Tool {
    let name = "Camera Color Picker"
    let icon = "eyedropper"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Identify and capture colors from the world around you using your camera"
    let requiresAPI = false
    var view: AnyView { AnyView(CameraColorPickerView()) }
}
