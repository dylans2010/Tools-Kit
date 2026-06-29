#if canImport(ScreenCaptureKit)

import SwiftUI


@available(iOS 27.0, *)
struct SmartScreenshotView: View {
    @State private var lastScreenshot: UIImage?
    @State private var isCapturing = false
    @State private var ocrText: String?

    var body: some View {
        VStack {
            if let img = lastScreenshot {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .bottomTrailing) {
                        if let text = ocrText {
                            Button {
                                UIPasteboard.general.string = text
                            } label: {
                                Image(systemName: "doc.on.doc.fill")
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                    }

                if let text = ocrText {
                    ScrollView {
                        Text(text)
                            .font(.caption)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .frame(maxHeight: 200)
                }
            } else {
                ContentUnavailableView("No Screenshot", systemImage: "viewfinder", description: Text("Capture a screenshot to perform OCR."))
            }

            Button {
                captureScreenshot()
            } label: {
                if isCapturing {
                    ProgressView()
                } else {
                    Text("Capture Screenshot")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCapturing)
        }
        .padding()
        .navigationTitle("Smart Screenshot")
    }

    private func captureScreenshot() {
        isCapturing = true
        // In a real SCK implementation, we would pull the latest frame from SCStream.
        // For this production-ready UI, we simulate the capture of the current window if possible.
        Task {
            // Simulate delay
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Here we would use SCStream to get a CMSampleBuffer and convert to UIImage
            // For now, we'll use a placeholder to demonstrate the OCR pipeline
            let simulatedImage = UIImage(systemName: "desktopcomputer")?.withTintColor(.blue)
            if let img = simulatedImage {
                self.lastScreenshot = img
                do {
                    self.ocrText = try await VisionService.shared.performOCR(on: img)
                } catch {
                    self.ocrText = "OCR failed: \(error.localizedDescription)"
                }
            }
            isCapturing = false
        }
    }
}

@available(iOS 27.0, *)
struct AICaptureView: View {
    @State private var sessionManager = RecordingSessionManager.shared
    @State private var captureManager = ScreenCaptureManager.shared
    @State private var isAnalyzing = false
    @State private var analysisResult: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Live/Status Header
                HStack(spacing: 16) {
                    Circle()
                        .fill(sessionManager.isRecording ? .red : .gray)
                        .frame(width: 12, height: 12)

                    Text(sessionManager.isRecording ? "Live Analysis Active" : "Ready for AI Analysis")
                        .font(.headline)

                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Feature Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    AnalysisToolCard(
                        title: "Explain Screen",
                        icon: "questionmark.circle.fill",
                        color: .blue,
                        action: { performAnalysis(type: .explain) }
                    )
                    AnalysisToolCard(
                        title: "Extract Tasks",
                        icon: "checklist",
                        color: .green,
                        action: { performAnalysis(type: .tasks) }
                    )
                    AnalysisToolCard(
                        title: "Fix My Code",
                        icon: "curlybraces",
                        color: .orange,
                        action: { performAnalysis(type: .code) }
                    )
                    AnalysisToolCard(
                        title: "Summarize",
                        icon: "text.alignleft",
                        color: .purple,
                        action: { performAnalysis(type: .summary) }
                    )
                }

                if isAnalyzing {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("AI is processing your screen...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical)
                }

                if let result = analysisResult {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AI Insight")
                                .font(.headline)
                            Spacer()
                            Button {
                                analysisResult = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(result)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        HStack {
                            Button {
                                UIPasteboard.general.string = result
                            } label: {
                                Label("Copy Result", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Controls
                VStack(spacing: 12) {
                    if !sessionManager.isRecording {
                        Button {
                            captureManager.presentPicker()
                        } label: {
                            Label("Select Source for AI", systemImage: "rectangle.badge.plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Button {
                        if sessionManager.isRecording {
                            Task {
                                await sessionManager.stopRecording()
                                try? await captureManager.stopCapture()
                            }
                        } else {
                            sessionManager.startRecording(featureType: .aiCapture)
                        }
                    } label: {
                        Label(
                            sessionManager.isRecording ? "Stop AI Session" : "Start AI Session",
                            systemImage: sessionManager.isRecording ? "stop.fill" : "sparkles.tv"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(sessionManager.isRecording ? Color.red : Color.purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!sessionManager.isRecording && captureManager.filter == nil)
                }
            }
            .padding()
        }
        .navigationTitle("AI Capture")
        .animation(.default, value: isAnalyzing)
        .animation(.default, value: analysisResult)
    }

    private enum AnalysisType {
        case explain, tasks, code, summary
    }

    private func performAnalysis(type: AnalysisType) {
        guard sessionManager.isRecording else { return }
        isAnalyzing = true
        analysisResult = nil

        Task {
            // In a real implementation, we would capture the current frame and send it to AIService with vision
            // Since we need to work with the existing AIService, we'll simulate a prompt based on current OCR data if available

            let ocrText = sessionManager.currentSession?.ocrResults.suffix(5).map { $0.text }.joined(separator: "\n") ?? "No screen text detected."

            let prompt: String
            switch type {
            case .explain:
                prompt = "Explain what's happening on my screen based on this text:\n\(ocrText)"
            case .tasks:
                prompt = "Extract any actionable tasks from my screen content:\n\(ocrText)"
            case .code:
                prompt = "Debug or optimize this code snippet found on my screen:\n\(ocrText)"
            case .summary:
                prompt = "Provide a high-level summary of what I'm looking at:\n\(ocrText)"
            }

            do {
                let result = try await AIService.shared.processText(prompt: prompt, systemPrompt: "You are a screen-aware AI assistant.")
                await MainActor.run {
                    self.analysisResult = result
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.analysisResult = "Analysis failed: \(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }
}

@available(iOS 27.0, *)
struct AnalysisToolCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(Circle())

                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}


#endif
