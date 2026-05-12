import SwiftUI

struct IDClassifierView: View {
    @StateObject private var backend = IDClassifierBackend()
    @StateObject private var cameraService = CameraService()

    var body: some View {
        ToolDetailView(tool: IDClassifierTool()) {
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

                if backend.isProcessing {
                    ProgressView("Analyzing ID...")
                } else if !backend.detectedInfo.isEmpty {
                    ToolInputSection("Detected Information") {
                        ForEach(backend.detectedInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(key).foregroundColor(.secondary)
                                Spacer()
                                Text(value).bold()
                            }
                            .padding()
                        }
                    }
                }
            }
        }
    }
}

struct IDClassifierTool: Tool, Sendable {
    let name = "ID Classifier"
    let icon = "person.text.rectangle"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Extract information from IDs, passports, and driver's licenses"
    let requiresAPI = false
    var view: AnyView { AnyView(IDClassifierView()) }
}
