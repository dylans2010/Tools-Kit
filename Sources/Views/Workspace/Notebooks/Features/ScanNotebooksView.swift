import SwiftUI

// MARK: - Scan AI Tool

enum ScanAITool: String, CaseIterable, Identifiable {
    case summarize        = "Summarize"
    case keyPoints        = "Key Points"
    case expandNotes      = "Expand Notes"
    case simplify         = "Simplify"
    case rewrite          = "Rewrite Professionally"
    case fixGrammar       = "Fix Grammar & Spelling"
    case translate        = "Translate"
    case createFlashcards = "Create Flashcards"
    case generateQuiz     = "Generate Quiz"
    case actionItems      = "Extract Action Items"
    case formatOutline    = "Format as Outline"
    case explainSimply    = "Explain Like I'm 5"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .summarize:        return "text.redaction"
        case .keyPoints:        return "list.bullet.rectangle.portrait"
        case .expandNotes:      return "arrow.up.left.and.arrow.down.right"
        case .simplify:         return "textformat.size.smaller"
        case .rewrite:          return "briefcase"
        case .fixGrammar:       return "textformat.abc"
        case .translate:        return "globe"
        case .createFlashcards: return "rectangle.on.rectangle.angled"
        case .generateQuiz:     return "questionmark.circle"
        case .actionItems:      return "checklist"
        case .formatOutline:    return "list.number"
        case .explainSimply:    return "lightbulb"
        }
    }

    var prompt: String {
        switch self {
        case .summarize:
            return "Summarize the following scanned notes concisely while preserving all key information:"
        case .keyPoints:
            return "Extract the most important key points from these scanned notes as a bullet list:"
        case .expandNotes:
            return "Expand and elaborate on the following scanned notes with additional detail and context:"
        case .simplify:
            return "Simplify the following scanned notes into plain, easy-to-understand language:"
        case .rewrite:
            return "Rewrite the following scanned notes in a polished, professional tone:"
        case .fixGrammar:
            return "Fix all grammar, spelling, and punctuation errors in the following scanned text while keeping the meaning:"
        case .translate:
            return "Translate the following scanned notes into Spanish:"
        case .createFlashcards:
            return "Create a set of study flashcards (Question / Answer pairs) from these scanned notes:"
        case .generateQuiz:
            return "Generate a quiz with 10 questions and answers based on these scanned notes:"
        case .actionItems:
            return "Extract all action items, tasks, and to-dos from these scanned notes as a checklist:"
        case .formatOutline:
            return "Reformat the following scanned notes into a well-structured outline with headings and sub-points:"
        case .explainSimply:
            return "Explain the following scanned notes in extremely simple terms as if explaining to a 5-year-old:"
        }
    }

    var systemPrompt: String {
        switch self {
        case .summarize:
            return "You are an expert note summarizer. Provide a clear, concise summary. Do not include any preamble."
        case .keyPoints:
            return "You are a key-point extractor. Return only a bullet-point list. No extra commentary."
        case .expandNotes:
            return "You are an expert note expander. Add depth, examples, and context while staying faithful to the source."
        case .simplify:
            return "You simplify complex text into plain English. Keep it short and clear."
        case .rewrite:
            return "You are a professional editor. Rewrite for clarity, tone, and polish. Keep the original meaning."
        case .fixGrammar:
            return "You are a meticulous proofreader. Fix all errors. Return only the corrected text."
        case .translate:
            return "You are a professional translator. Translate accurately while preserving tone and meaning."
        case .createFlashcards:
            return "You create study flashcards. Format each card as Q: / A: pairs. Be thorough."
        case .generateQuiz:
            return "You generate educational quizzes. Provide questions with multiple-choice answers and mark the correct one."
        case .actionItems:
            return "You extract actionable tasks. Return a clean checklist. No extra commentary."
        case .formatOutline:
            return "You format text into structured outlines with clear hierarchy. Use Roman numerals or numbered headings."
        case .explainSimply:
            return "You explain complex topics in extremely simple language. Use short sentences and everyday words."
        }
    }
}

// MARK: - Scan Step

enum ScanStep: Int, CaseIterable {
    case capture = 1
    case review  = 2
    case aiTools = 3
}

// MARK: - View Model

@MainActor
final class ScanNotebooksViewModel: ObservableObject {
    @Published var currentStep: ScanStep = .capture
    @Published var isTransitioning = false
    @Published var selectedTool: ScanAITool?
    @Published var customPrompt = ""
    @Published var aiResult = ""
    @Published var isProcessingAI = false
    @Published var didCopy = false

    func processWithTool(_ tool: ScanAITool, text: String) {
        selectedTool = tool
        isProcessingAI = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            do {
                let prompt = "\(tool.prompt)\n\n\(text)"
                let result = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: tool.systemPrompt
                )
                self.aiResult = result
                self.isProcessingAI = false
            } catch {
                self.aiResult = "Error: \(error.localizedDescription)"
                self.isProcessingAI = false
            }
        }
    }

    func processCustomPrompt(text: String) {
        guard !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isProcessingAI = true
        selectedTool = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            do {
                let prompt = "\(customPrompt)\n\nScanned content:\n\(text)"
                let result = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: "You are a helpful AI assistant. Follow the user's instructions precisely using the scanned content provided."
                )
                self.aiResult = result
                self.isProcessingAI = false
            } catch {
                self.aiResult = "Error: \(error.localizedDescription)"
                self.isProcessingAI = false
            }
        }
    }

    func copyResult() {
        UIPasteboard.general.string = aiResult
        didCopy = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.didCopy = false
        }
    }

    func resetAIResult() {
        aiResult = ""
        selectedTool = nil
        customPrompt = ""
    }
}

// MARK: - ScanNotebooksView

struct ScanNotebooksView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine = ScanNotebooksEngine()
    @StateObject private var viewModel = ScanNotebooksViewModel()
    @State private var didCopyExtracted = false

    private var isAnyLoading: Bool {
        engine.isCapturing || engine.isExtracting || viewModel.isProcessingAI || viewModel.isTransitioning
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    stepIndicator

                    ScrollView {
                        VStack(spacing: 24) {
                            stepContent
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                        .padding()
                    }

                    if viewModel.currentStep != .aiTools || viewModel.aiResult.isEmpty {
                        navigationButtons
                    }
                }
            }
            .navigationTitle("Scan Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        engine.stopSession()
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                    .disabled(isAnyLoading)
                }
            }
            .onAppear { engine.requestCameraAccess() }
            .onDisappear { engine.stopSession() }
            .modifier(AIAnimationCoreModifier(isLoading: viewModel.isProcessingAI))
            .overlay {
                if viewModel.isProcessingAI {
                    loadingOverlay
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Processing with AI...")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 50)
        }
        .zIndex(200)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(ScanStep.allCases, id: \.rawValue) { step in
                VStack(spacing: 4) {
                    Capsule()
                        .fill(
                            viewModel.currentStep == step
                                ? Color.accentColor
                                : (viewModel.currentStep.rawValue > step.rawValue
                                   ? Color.accentColor.opacity(0.4)
                                   : Color(.tertiarySystemBackground))
                        )
                        .frame(height: 6)

                    Text(stepLabel(for: step))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(
                            viewModel.currentStep == step ? .accentColor : .secondary
                        )
                }
                .animation(.spring(), value: viewModel.currentStep)
            }
        }
        .padding()
    }

    private func stepLabel(for step: ScanStep) -> String {
        switch step {
        case .capture:  return "Capture"
        case .review:   return "Review"
        case .aiTools:  return "AI Tools"
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .capture:
            captureStepView
                .id(ScanStep.capture)
        case .review:
            reviewStepView
                .id(ScanStep.review)
        case .aiTools:
            aiToolsStepView
                .id(ScanStep.aiTools)
        }
    }

    // MARK: Step 1 — Capture

    private var captureStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Capture Your Notes")
                .font(.title2.bold())

            Text("Point your camera at handwritten or printed notes to extract text.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if engine.cameraPermissionDenied {
                cameraPermissionDeniedView
            } else if let image = engine.capturedImage {
                capturedImagePreview(image)
            } else {
                cameraLivePreview
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var cameraPermissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Camera Access Required")
                .font(.headline)
            Text("Open Settings and enable camera access for this app.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func capturedImagePreview(_ image: UIImage) -> some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                )

            if engine.isExtracting {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Extracting text...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let error = engine.extractionError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.red)
            } else if !engine.extractedText.isEmpty {
                Label("Text extracted successfully!", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    engine.retryCapture()
                } label: {
                    Label("Retake", systemImage: "arrow.counterclockwise")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
        }
    }

    private var cameraLivePreview: some View {
        VStack(spacing: 16) {
            if engine.isCameraReady {
                ZStack(alignment: .bottom) {
                    CameraPreviewView(session: engine.captureSession)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                        )

                    Button {
                        engine.capturePhoto()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 70, height: 70)
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 4)
                                .frame(width: 70, height: 70)
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 58, height: 58)
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(engine.isCapturing)
                    .padding(.bottom, 16)
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Starting camera...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 320)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Step 2 — Review

    private var reviewStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Extracted Content")
                .font(.title2.bold())

            if engine.extractedText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No text extracted yet. Go back to capture your notes.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    Text(engine.extractedText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 350)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                )

                let wordCount = engine.extractedText.split { $0.isWhitespace }.count
                let charCount = engine.extractedText.count

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        statChip(icon: "textformat.123", label: "\(wordCount) words")
                        statChip(icon: "character.cursor.ibeam", label: "\(charCount) chars")
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = engine.extractedText
                        didCopyExtracted = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { didCopyExtracted = false }
                    } label: {
                        Label(didCopyExtracted ? "Copied!" : "Copy Text", systemImage: didCopyExtracted ? "checkmark" : "doc.on.doc")
                            .font(.caption.bold())
                            .foregroundColor(didCopyExtracted ? .green : .accentColor)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        engine.retryCapture()
                        transitionToStep(.capture)
                    } label: {
                        Label("Scan Again", systemImage: "arrow.counterclockwise")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Step 3 — AI Tools

    private var aiToolsStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !viewModel.aiResult.isEmpty {
                aiResultView
            } else {
                aiToolSelectionView
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var aiToolSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Tools")
                .font(.title2.bold())

            Text("Choose an AI tool to process your scanned notes, or type a custom instruction.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Custom prompt
            VStack(alignment: .leading, spacing: 8) {
                Label("Custom Instruction", systemImage: "text.cursor")
                    .font(.subheadline.bold())

                HStack(spacing: 8) {
                    TextField("Type what you want to do...", text: $viewModel.customPrompt)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        viewModel.processCustomPrompt(text: engine.extractedText)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .disabled(viewModel.customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isProcessingAI)
                }
            }

            Divider()

            Label("Preset Tools", systemImage: "wand.and.stars")
                .font(.subheadline.bold())

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(ScanAITool.allCases) { tool in
                    Button {
                        viewModel.processWithTool(tool, text: engine.extractedText)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tool.icon)
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            Text(tool.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                        )
                    }
                    .foregroundColor(.primary)
                    .disabled(viewModel.isProcessingAI)
                }
            }
        }
    }

    private var aiResultView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(
                    viewModel.selectedTool?.rawValue ?? "Custom Result",
                    systemImage: viewModel.selectedTool?.icon ?? "text.cursor"
                )
                .font(.title3.bold())

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.resetAIResult()
                } label: {
                    Label("Back to Tools", systemImage: "arrow.uturn.backward")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemBackground), in: Capsule())
                }
                .disabled(viewModel.isProcessingAI)
            }

            ScrollView {
                Text(viewModel.aiResult)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 400)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
            )

            HStack(spacing: 10) {
                Button {
                    viewModel.copyResult()
                } label: {
                    Label(viewModel.didCopy ? "Copied!" : "Copy", systemImage: viewModel.didCopy ? "checkmark" : "doc.on.doc")
                        .font(.caption.bold())
                        .foregroundColor(viewModel.didCopy ? .green : .accentColor)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .disabled(viewModel.isProcessingAI)

                ShareLink(item: viewModel.aiResult) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .disabled(viewModel.isProcessingAI)

                Spacer()

                Button {
                    engine.stopSession()
                    dismiss()
                } label: {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(viewModel.isProcessingAI)
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep.rawValue > 1 {
                Button {
                    let prev = ScanStep(rawValue: viewModel.currentStep.rawValue - 1) ?? .capture
                    transitionToStep(prev)
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.tertiarySystemBackground))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isAnyLoading)
            }

            if viewModel.currentStep.rawValue < ScanStep.allCases.count {
                Button {
                    let next = ScanStep(rawValue: viewModel.currentStep.rawValue + 1) ?? .aiTools
                    transitionToStep(next)
                } label: {
                    Label(nextButtonLabel, systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canAdvance ? Color.accentColor : Color.gray.opacity(0.3))
                        .foregroundColor(canAdvance ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canAdvance || isAnyLoading)
            }
        }
        .padding()
    }

    private var nextButtonLabel: String {
        switch viewModel.currentStep {
        case .capture: return "Review Text"
        case .review:  return "Use AI Tools"
        case .aiTools: return "Next"
        }
    }

    private var canAdvance: Bool {
        switch viewModel.currentStep {
        case .capture:
            return !engine.extractedText.isEmpty
        case .review:
            return !engine.extractedText.isEmpty
        case .aiTools:
            return false
        }
    }

    // MARK: - Helpers

    private func transitionToStep(_ step: ScanStep) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.isTransitioning = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            viewModel.currentStep = step
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            viewModel.isTransitioning = false
        }
    }

    private func statChip(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.accentColor)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemBackground), in: Capsule())
    }
}
