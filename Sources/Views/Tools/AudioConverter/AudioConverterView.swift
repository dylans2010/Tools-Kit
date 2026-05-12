import SwiftUI

struct AudioConverterView: View {
    @StateObject private var backend = AudioConverterBackend()
    @State private var showingFilePicker = false

    var body: some View {
        ToolDetailView(tool: AudioConverterTool()) {
            VStack(spacing: 24) {
                Button(action: { showingFilePicker = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                        Text("Select Audio File")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [6]))
                    )
                }

                if backend.isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(backend.status)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            FileImporterRepresentableView(allowedContentTypes: [.audio]) { urls in
                Task {
                    do {
                        if let url = urls.first {
                            let _ = try await backend.convertToM4A(inputURL: url)
                        }
                    } catch {
                        print("Conversion failed: \(error)")
                    }
                }
            }
        }
    }
}

struct AudioConverterTool: Tool, Sendable {
    let name = "Audio Converter"
    let icon = "waveform"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Convert audio files between different formats like M4A and WAV"
    let requiresAPI = false
    var view: AnyView { AnyView(AudioConverterView()) }
}
