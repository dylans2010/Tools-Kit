import SwiftUI

struct VideoCompressorView: View {
    @StateObject private var backend = VideoCompressorBackend()
    @State private var showingPicker = false

    var body: some View {
        ToolDetailView(tool: VideoCompressorTool()) {
            VStack(spacing: 24) {
                Button(action: { showingPicker = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 48))
                        Text("Select Video")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                }

                if backend.isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Compressing Video...")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            FileImporterRepresentableView(allowedContentTypes: [.movie]) { urls in
                Task {
                    if let url = urls.first {
                        try? await backend.compressVideo(at: url)
                    }
                }
            }
        }
    }
}

struct VideoCompressorTool: Tool {
    let name = "Video Compressor"
    let icon = "video.circle"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Reduce video file size while maintaining quality"
    let requiresAPI = false
    var view: AnyView { AnyView(VideoCompressorView()) }
}
