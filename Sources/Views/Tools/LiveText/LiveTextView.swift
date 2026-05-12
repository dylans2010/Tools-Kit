import SwiftUI

struct LiveTextView: View {
    @StateObject private var backend = LiveTextBackend()
    @StateObject private var cameraService = CameraService()

    var body: some View {
        ToolDetailView(tool: LiveTextTool()) {
            VStack(spacing: 24) {
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

                if !backend.recognizedText.isEmpty {
                    ToolOutputView("Recognized Text", value: backend.recognizedText)
                } else if backend.isProcessing {
                    ProgressView()
                }
            }
        }
    }
}

struct LiveTextTool: Tool, Sendable {
    let name = "Live Text"
    let icon = "text.viewfinder"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Instantly recognize and copy text from the camera feed"
    let requiresAPI = false
    var view: AnyView { AnyView(LiveTextView()) }
}
