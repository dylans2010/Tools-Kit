import SwiftUI

struct MealVoiceLoggingView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @StateObject private var voiceService = MealVoiceService()

    @State private var lastSavedMeal: MealRecord?
    @State private var isSaving = false
    @State private var errorMessage: String?

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
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Button("Retry") {
                    lastSavedMeal = nil
                    voiceService.reset()
                    errorMessage = nil
                }
                .buttonStyle(.bordered)

                Button("Confirm") {
                    Task { await saveVoiceMeal() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(voiceService.cleanedOutput().isEmpty || isSaving)
            }

            if let lastSavedMeal {
                Text("Saved: \(lastSavedMeal.calories) kcal · \(lastSavedMeal.detectedItems.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let error = voiceService.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Voice Meal")
        .presentationDetents([.medium, .large])
        .task {
            await voiceService.requestPermissions()
        }
    }

    @MainActor
    private func saveVoiceMeal() async {
        let cleaned = voiceService.cleanedOutput()
        guard !cleaned.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }

        let input = NutritionAIInput(
            rawText: cleaned,
            sourceType: .voice,
            imageData: nil,
            voiceTranscript: cleaned
        )

        let result = await manager.logMeal(using: input)
        switch result {
        case .success(let meal):
            lastSavedMeal = meal
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
