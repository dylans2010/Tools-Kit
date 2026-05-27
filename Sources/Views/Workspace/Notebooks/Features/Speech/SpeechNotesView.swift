import SwiftUI

struct SpeechNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechManager = SpeechManager()
    @State private var isProcessing = false
    @State private var processedResult = ""
    @State private var selectedAction: SpeechAIAction?
    @State private var showingOptions = false

    // Waveform state for animation
    @State private var waveformLevels: [CGFloat] = Array(repeating: 10, count: 8)
    @State private var timer: Timer?

    var onComplete: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !processedResult.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("AI Result")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text(processedResult)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                    }
                } else {
                    Spacer()

                    VStack(spacing: 16) {
                        if speechManager.isRecording {
                            waveformView
                        } else {
                            Image(systemName: "waveform")
                                .font(.system(size: 60))
                                .foregroundStyle(.accent)
                        }

                        Text(speechManager.isRecording ? "Listening..." : "Tap to Record")
                            .font(.headline)
                    }

                    ScrollView {
                        Text(speechManager.transcription.isEmpty ? (speechManager.isRecording ? "Transcription will appear here..." : "") : speechManager.transcription)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                            .foregroundStyle(speechManager.transcription.isEmpty ? .secondary : .primary)
                    }
                    .frame(maxHeight: 200)

                    Spacer()

                    recordButton
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("Speech Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                if !processedResult.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Insert") {
                            onComplete(processedResult)
                            dismiss()
                        }
                    }
                } else if !speechManager.transcription.isEmpty && !speechManager.isRecording {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("AI Options") {
                            showingOptions = true
                        }
                    }
                }
            }
            .confirmationDialog("What should AI do?", isPresented: $showingOptions, titleVisibility: .visible) {
                ForEach(SpeechAIAction.allCases) { action in
                    Button(action.rawValue) {
                        performAIAction(action)
                    }
                }
                Button("Just Insert Transcript") {
                    onComplete(speechManager.transcription)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("AI is processing...")
                                .font(.headline)
                        }
                        .padding(30)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .onAppear {
                startWaveformTimer()
            }
            .onDisappear {
                stopWaveformTimer()
            }
        }
    }

    private var recordButton: some View {
        Button {
            if speechManager.isRecording {
                speechManager.stopRecording()
                if !speechManager.transcription.isEmpty {
                    showingOptions = true
                }
            } else {
                do {
                    try speechManager.startRecording()
                } catch {
                    print("Error starting recording: \(error)")
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(speechManager.isRecording ? .red : .accentColor)
                    .frame(width: 80, height: 80)

                if speechManager.isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 30, height: 30)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                }
            }
            .shadow(radius: 10)
        }
    }

    private var waveformView: some View {
        HStack(spacing: 4) {
            ForEach(0..<8) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 4, height: waveformLevels[i])
            }
        }
        .frame(height: 60)
    }

    private func startWaveformTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if speechManager.isRecording {
                withAnimation(.easeInOut(duration: 0.1)) {
                    for i in 0..<8 {
                        waveformLevels[i] = CGFloat.random(in: 10...60)
                    }
                }
            } else {
                if waveformLevels.first != 10 {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        waveformLevels = Array(repeating: 10, count: 8)
                    }
                }
            }
        }
    }

    private func stopWaveformTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func performAIAction(_ action: SpeechAIAction) {
        isProcessing = true
        let prompt: String
        switch action {
        case .summarize:
            prompt = "Summarize the following spoken notes concisely:\n\n\(speechManager.transcription)"
        case .keyPoints:
            prompt = "Extract key points from these spoken notes:\n\n\(speechManager.transcription)"
        case .actionItems:
            prompt = "Identify action items from these spoken notes:\n\n\(speechManager.transcription)"
        case .clarify:
            prompt = "Clarify and polish these spoken notes to be more professional:\n\n\(speechManager.transcription)"
        case .expand:
            prompt = "Expand on the ideas mentioned in these spoken notes:\n\n\(speechManager.transcription)"
        }

        Task {
            do {
                let result = try await AIService.shared.processText(prompt: prompt)
                await MainActor.run {
                    self.processedResult = result
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.processedResult = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
}
