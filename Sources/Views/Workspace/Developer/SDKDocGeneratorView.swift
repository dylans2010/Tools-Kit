import SwiftUI

struct SDKDocGeneratorView: View {
    @State private var isGenerating = false
    @State private var progress: Double = 0.0
    @State private var selectedFormat = "Markdown"
    @State private var includePrivate = false

    var body: some View {
        Form {
            Section("Configuration") {
                Picker("Output Format", selection: $selectedFormat) {
                    Text("Markdown").tag("Markdown")
                    Text("HTML").tag("HTML")
                    Text("DocC Archive").tag("DocC")
                }
                Toggle("Include Private Symbols", isOn: $includePrivate)
            }

            Section("Execution") {
                Button(action: startGeneration) {
                    if isGenerating {
                        HStack {
                            Text("Generating...")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Label("Start Generation", systemImage: "book.closed.fill")
                    }
                }
                .disabled(isGenerating)

                if isGenerating {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: progress)
                        Text("\(Int(progress * 100))% - Processing Header Files")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Recent Documentation") {
                Label("SDK_Manual_v1.2.0.md", systemImage: "doc.text")
                    .font(.subheadline)
                Label("API_Reference_Internal.html", systemImage: "doc.text")
                    .font(.subheadline)
            }
        }
        .navigationTitle("Doc Generator")
    }

    private func startGeneration() {
        isGenerating = true
        progress = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.05
            if progress >= 1.0 {
                timer.invalidate()
                isGenerating = false
            }
        }
    }
}
