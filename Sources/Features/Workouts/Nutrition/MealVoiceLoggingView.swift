import SwiftUI

struct MealVoiceLoggingView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @StateObject private var voiceService = MealVoiceService()

    @State private var analysis: MealAnalysis?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Button {
                voiceService.isRecording ? voiceService.stopRecording() : voiceService.startRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(voiceService.isRecording ? Color.red : Color.accentColor)
                        .frame(width: 140, height: 140)
                    Image(systemName: voiceService.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            if voiceService.isRecording {
                ProgressView("Recording…")
                    .progressViewStyle(.circular)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Transcription")
                    .font(.headline)
                Text(voiceService.transcription.isEmpty ? "Say your meal details..." : voiceService.transcription)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Button("Retry") {
                    analysis = nil
                    voiceService.reset()
                }
                .buttonStyle(.bordered)

                Button("Confirm") {
                    let cleaned = voiceService.cleanedOutput()
                    guard !cleaned.isEmpty else { return }
                    let result = manager.analyzeMealInput(cleaned, sourceType: .voice, imageData: nil)
                    analysis = result
                    manager.addMeal(
                        name: cleaned.components(separatedBy: ",").first?.capitalized ?? "Voice Meal",
                        analysis: result,
                        sourceType: .voice,
                        rawInput: cleaned
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(voiceService.cleanedOutput().isEmpty)
            }

            if let analysis {
                Text("Saved: \(analysis.calories) kcal · \(analysis.detectedItems.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let error = voiceService.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Voice Meal")
        .task {
            await voiceService.requestPermissions()
        }
    }
}
