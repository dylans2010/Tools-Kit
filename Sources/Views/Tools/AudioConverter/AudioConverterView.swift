import SwiftUI

struct AudioConverterView: View {
    @State private var showingPicker = false
    @State private var selectedAudio: URL?
    @State private var isConverting = false

    var body: some View {
        VStack(spacing: 20) {
            if let audio = selectedAudio {
                Label(audio.lastPathComponent, systemImage: "music.note")
                    .font(.headline)
            } else {
                Button(action: { showingPicker = true }) {
                    VStack {
                        Image(systemName: "music.quaver.bowed.badge.plus")
                            .font(.system(size: 60))
                        Text("Select Audio File")
                    }
                }
            }

            if selectedAudio != nil {
                Picker("Output Format", selection: .constant("MP3")) {
                    Text("MP3").tag("MP3")
                    Text("M4A").tag("M4A")
                    Text("WAV").tag("WAV")
                }
                .pickerStyle(.segmented)
                .padding()

                Button(action: { isConverting = true }) {
                    if isConverting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Convert Audio")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .navigationTitle("Audio Converter")
        .sheet(isPresented: $showingPicker) {
            FileImporterRepresentableView(allowedContentTypes: [.audio]) { urls in
                selectedAudio = urls.first
            }
        }
    }
}

struct AudioConverterTool: Tool {
    let name = "Audio Converter"
    let icon = "waveform"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Convert between MP3, WAV, and M4A formats"
    let requiresAPI = false
    var view: AnyView { AnyView(AudioConverterView()) }
}
