import SwiftUI

struct PerspectiveCorrectorView: View {
    @StateObject private var backend = PerspectiveCorrectorBackend()
    @StateObject private var cameraService = CameraService()

    var body: some View {
        ToolDetailView(tool: PerspectiveCorrectorTool()) {
            VStack(spacing: 24) {
                if let image = backend.processedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                } else {
                    CameraPreview(cameraService: cameraService)
                        .onAppear {
                            cameraService.delegate = backend
                            cameraService.startSession()
                        }
                        .onDisappear {
                            cameraService.stopSession()
                        }
                        .frame(height: 300)
                        .cornerRadius(16)
                }
            }
        }
    }
}

struct PerspectiveCorrectorTool: Tool {
    let name = "Perspective Corrector"
    let icon = "skew"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Fix distorted photos of documents and signs"
    let requiresAPI = false
    var view: AnyView { AnyView(PerspectiveCorrectorView()) }
}
