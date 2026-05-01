import SwiftUI

struct AudioEnhancementView: View {
    @StateObject private var manager = AudioEnhancementManager.shared
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Enhancement").font(.headline)

            VStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Noise Reduction").font(.caption)
                    Slider(value: $manager.config.noiseReductionIntensity)
                }

                Toggle("Voice Isolation", isOn: $manager.config.voiceEnhancement)
                Toggle("Loudness Normalization", isOn: $manager.config.normalization)

                VStack(alignment: .leading) {
                    Text("De-reverb").font(.caption)
                    Slider(value: $manager.config.reverbRemoval)
                }
            }

            Button(action: applyEnhancements) {
                if isProcessing {
                    ProgressView().tint(.white)
                } else {
                    Text("Apply to Selected Track")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    private func applyEnhancements() {
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isProcessing = false
        }
    }
}
