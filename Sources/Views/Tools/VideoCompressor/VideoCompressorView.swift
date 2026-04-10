import SwiftUI

struct VideoCompressorView: View {
    @State private var showingPicker = false
    @State private var selectedVideo: URL?
    @State private var compressionLevel = 0.5

    var body: some View {
        VStack(spacing: 20) {
            if let video = selectedVideo {
                Label(video.lastPathComponent, systemImage: "video.fill")
                    .font(.headline)
            } else {
                Button(action: { showingPicker = true }) {
                    VStack {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 60))
                        Text("Select Video File")
                    }
                }
            }

            if selectedVideo != nil {
                VStack {
                    Text("Compression Quality: \(Int(compressionLevel * 100))%")
                    Slider(value: $compressionLevel)
                }
                .padding()

                Button("Compress Video") {
                    // Logic for AVAssetExportSession
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .navigationTitle("Video Compressor")
        .sheet(isPresented: $showingPicker) {
            FileImporterRepresentableView(allowedContentTypes: [.movie]) { urls in
                selectedVideo = urls.first
            }
        }
    }
}

struct VideoCompressorTool: Tool {
    let name = "Video Compressor"
    let icon = "video.circle.fill"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Reduce video file size without significant quality loss"
    let requiresAPI = false
    var view: AnyView { AnyView(VideoCompressorView()) }
}
