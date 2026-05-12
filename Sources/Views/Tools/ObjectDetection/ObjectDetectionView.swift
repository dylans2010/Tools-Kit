import SwiftUI

struct ObjectDetectionView: View {
    @StateObject private var backend = ObjectDetectionBackend()
    @StateObject private var cameraService = CameraService()

    var body: some View {
        ToolDetailView(tool: ObjectDetectionTool()) {
            VStack(spacing: 24) {
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

                if !backend.detectedObjects.isEmpty {
                    ToolInputSection("Detected Objects") {
                        ForEach(backend.detectedObjects, id: \.self) { obj in
                            Text(obj).padding()
                        }
                    }
                }
            }
        }
    }
}

struct ObjectDetectionTool: Tool, Sendable {
    let name = "Object Detection"
    let icon = "viewfinder.circle"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Real-time identification of objects and scenes using AI"
    let requiresAPI = false
    var view: AnyView { AnyView(ObjectDetectionView()) }
}
