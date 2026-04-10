import SwiftUI
import Vision

struct LiveTextView: View {
    @State private var extractedText = ""
    @State private var isScanning = false
    @State private var scanCount = 0

    var body: some View {
        VStack {
            ZStack {
                Color.black
                Text("Live Camera Feed")
                    .foregroundColor(.white)

                if !extractedText.isEmpty {
                    VStack {
                        Spacer()
                        ScrollView {
                            Text(extractedText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .padding()

            HStack {
                Button(isScanning ? "Stop Scanning" : "Start Live Text") {
                    isScanning.toggle()
                    if isScanning {
                        scanCount += 1
                        extractedText = "Capture #\(scanCount): Sample extracted text from camera..."
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Copy") { UIPasteboard.general.string = extractedText }
                    .buttonStyle(.bordered)
                    .disabled(extractedText.isEmpty)

                Button("Clear") { extractedText = "" }
                    .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Live Text")
    }
}

struct LiveTextTool: Tool {
    let name = "Live Text"
    let icon = "text.viewfinder"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Real-time text extraction from live camera feed"
    let requiresAPI = false
    var view: AnyView { AnyView(LiveTextView()) }
}
