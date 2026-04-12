import SwiftUI

struct SmartAutofillView: View {
    @StateObject private var backend = SmartAutofillBackend()
    @StateObject private var cameraService = CameraService()

    var body: some View {
        ToolDetailView(tool: SmartAutofillTool()) {
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

                Text("Point your camera at a paper form to identify fields for autofill.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct SmartAutofillTool: Tool {
    let name = "Smart Autofill"
    let icon = "square.and.pencil"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Automatically detect and fill form fields from physical documents"
    let requiresAPI = false
    var view: AnyView { AnyView(SmartAutofillView()) }
}
