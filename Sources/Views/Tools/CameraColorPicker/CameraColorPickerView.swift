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
                                        .fill(Color(hex: hex) ?? .clear)
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

struct CameraColorPickerTool: Tool {
    let name = "Camera Color Picker"
    let icon = "eyedropper"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Identify and capture colors from the world around you using your camera"
    let requiresAPI = false
    var view: AnyView { AnyView(CameraColorPickerView()) }
}
