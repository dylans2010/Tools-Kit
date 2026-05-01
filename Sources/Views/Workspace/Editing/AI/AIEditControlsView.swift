import SwiftUI

struct AIEditControlsView: View {
    @StateObject private var aiEngine = AIEditingEngine.shared
    @State private var prompt = ""
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 20) {
            Text("AI Editing Tools")
                .font(.headline)

            VStack(alignment: .leading) {
                Text("Generative Background")
                    .font(.subheadline)
                TextField("Enter prompt (e.g., 'sunset on Mars')", text: $prompt)
                    .textFieldStyle(.roundedBorder)

                Button(action: {
                    isProcessing = true
                    Task {
                        let _ = await aiEngine.generateBackground(prompt: prompt)
                        isProcessing = false
                    }
                }) {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Text("Generate & Apply")
                    }
                }
                .disabled(prompt.isEmpty || isProcessing)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)

            Divider()

            HStack {
                Button("Smart Remove") {
                    // Enter selection mode
                }
                .buttonStyle(.bordered)

                Button("Auto Grade") {
                    // Apply suggested grading
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
