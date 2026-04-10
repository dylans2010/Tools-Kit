import SwiftUI
import Vision

struct LiveTextView: View {
    @State private var extractedText = ""
    @State private var isScanning = false

    var body: some View {
        VStack {
            ZStack {
                Color.black
                Text("Live Camera Feed")
                    .foregroundColor(.white)

                if !extractedText.isEmpty {
                    VStack {
                        Spacer()
                        Text(extractedText)
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

            Button(isScanning ? "Stop Scanning" : "Start Live Text") {
                isScanning.toggle()
                if isScanning { extractedText = "Sample extracted text from camera..." }
            }
            .buttonStyle(.borderedProminent)
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
