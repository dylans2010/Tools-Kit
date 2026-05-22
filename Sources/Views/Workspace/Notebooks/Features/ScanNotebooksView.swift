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

    // Mode selection
    @Published var selectedExtractionMode: ScanExtractionMode = .fullText

    // Chat
    @Published var chatInput = ""

    // Transform
    @Published var selectedTransformTarget: ScanTransformTarget?
    @Published var showTransformSheet = false

    // History
    @Published var historyFilter: ScanHistoryFilter = .all
    @Published var historySearchQuery = ""

    // Active scan for chat/transform
    @Published var activeScanID: UUID?

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
    @State private var showHistorySheet = false

    private var isAnyLoading: Bool {
        engine.isCapturing || engine.isExtracting || viewModel.isProcessingAI
        || viewModel.isTransitioning || engine.isProcessingStructured
        || engine.isChatProcessing || engine.isTransforming
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    topTabBar

                    ScrollView {
                        VStack(spacing: 24) {
                            mainContent
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                        .padding()
                    }

                    if shouldShowNavButtons {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHistorySheet = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
            .onAppear { engine.requestCameraAccess() }
            .onDisappear { engine.stopSession() }
            .modifier(AIAnimationCoreModifier(isLoading: viewModel.isProcessingAI || engine.isProcessingStructured || engine.isChatProcessing || engine.isTransforming))
            .overlay {
                if viewModel.isProcessingAI || engine.isProcessingStructured || engine.isTransforming {
                    loadingOverlay
                        .transition(.opacity)
                }
            }
            .sheet(isPresented: $showHistorySheet) {
                scanHistorySheet
            }
            .sheet(isPresented: $viewModel.showTransformSheet) {
                transformSheet
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

    // MARK: - Top Tab Bar

    private var topTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                tabBarButton("Capture", icon: "camera.fill", step: .capture)
                tabBarButton("Review", icon: "doc.text.magnifyingglass", step: .review)
                tabBarButton("AI Tools", icon: "wand.and.stars", step: .aiTools)
                tabBarButton("Chat", icon: "bubble.left.and.bubble.right.fill", step: .chat)
                tabBarButton("Transform", icon: "arrow.triangle.branch", step: .transform)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground).opacity(0.5))
    }

    private func tabBarButton(_ title: String, icon: String, step: ScanStep) -> some View {
        Button {
            transitionToStep(step)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                viewModel.currentStep == step
                    ? Color.accentColor
                    : Color(.tertiarySystemBackground)
            )
            .foregroundColor(viewModel.currentStep == step ? .white : .primary)
            .clipShape(Capsule())
        }
        .animation(.spring(), value: viewModel.currentStep)
    }

    private var shouldShowNavButtons: Bool {
        switch viewModel.currentStep {
        case .capture, .review:
            return true
        case .aiTools:
            return viewModel.aiResult.isEmpty
        case .chat, .transform, .history:
            return false
        }
    }

    // MARK: - Main Content Router

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.currentStep {
        case .capture:
            captureStepView.id(ScanStep.capture)
        case .review:
            reviewStepView.id(ScanStep.review)
        case .aiTools:
            aiToolsStepView.id(ScanStep.aiTools)
        case .chat:
            chatStepView.id(ScanStep.chat)
        case .transform:
            transformStepView.id(ScanStep.transform)
        case .history:
            historyStepView.id(ScanStep.history)
        }
    }

    // MARK: - Step 1: Capture

    private var captureStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Capture Your Notes")
                .font(.title2.bold())

            Text("Point your camera at handwritten or printed notes to extract text.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Mode selection
            modeSelectionBar

            // Quality feedback
            if !engine.qualityIssues.isEmpty {
                qualityFeedbackBar
            }

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

    private var modeSelectionBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Extraction Mode", systemImage: "slider.horizontal.3")
                .font(.subheadline.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ScanExtractionMode.allCases) { mode in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            engine.selectedExtractionMode = mode
                            viewModel.selectedExtractionMode = mode
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: mode.icon)
                                    .font(.caption2)
                                Text(mode.rawValue)
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedExtractionMode == mode
                                    ? Color.accentColor
                                    : Color(.tertiarySystemBackground)
                            )
                            .foregroundColor(viewModel.selectedExtractionMode == mode ? .white : .primary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        viewModel.selectedExtractionMode == mode
                                            ? Color.accentColor
                                            : Color(.separator).opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
            }
        }
    }

    private var qualityFeedbackBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(engine.qualityIssues) { issue in
                HStack(spacing: 8) {
                    Image(systemName: issue.icon)
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(issue.rawValue)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                    )

                // Unreadable region highlights
                GeometryReader { geo in
                    ForEach(Array(engine.unreadableRegions.enumerated()), id: \.offset) { _, rect in
                        Rectangle()
                            .fill(Color.red.opacity(0.2))
                            .border(Color.red.opacity(0.5), width: 1)
                            .frame(
                                width: rect.width * geo.size.width,
                                height: rect.height * geo.size.height
                            )
                            .position(
                                x: rect.midX * geo.size.width,
                                y: (1 - rect.midY) * geo.size.height
                            )
                    }
                }
            }

            // OCR confidence bar
            if engine.ocrConfidence < 1.0 {
                HStack(spacing: 8) {
                    Image(systemName: engine.ocrConfidence > 0.7 ? "checkmark.circle" : "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(engine.ocrConfidence > 0.7 ? .green : .orange)
                    Text("OCR Confidence: \(Int(engine.ocrConfidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    ProgressView(value: engine.ocrConfidence)
                        .frame(width: 80)
                        .tint(engine.ocrConfidence > 0.7 ? .green : .orange)
                }
            }

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

    // MARK: - Step 2: Review

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
                // Structured result display
                if let result = engine.structuredResult {
                    structuredResultView(result)
                } else {
                    rawTextView
                }

                // Detected structures
                if !engine.detectedStructures.isEmpty {
                    detectedStructuresSection
                }

                let wordCount = engine.extractedText.split { $0.isWhitespace }.count
                let charCount = engine.extractedText.count

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        statChip(icon: "textformat.123", label: "\(wordCount) words")
                        statChip(icon: "character.cursor.ibeam", label: "\(charCount) chars")
                        if engine.ocrConfidence < 1.0 {
                            statChip(
                                icon: "gauge",
                                label: "\(Int(engine.ocrConfidence * 100))% confidence"
                            )
                        }
                        statChip(
                            icon: "doc.text.below.ecg",
                            label: "\(engine.detectedStructures.count) structures"
                        )
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

                    if engine.structuredResult == nil && viewModel.selectedExtractionMode != .fullText {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            engine.performStructuredExtraction(mode: viewModel.selectedExtractionMode)
                        } label: {
                            Label("Extract \(viewModel.selectedExtractionMode.rawValue)", systemImage: "sparkles")
                                .font(.caption.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .disabled(engine.isProcessingStructured)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var rawTextView: some View {
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
    }

    @ViewBuilder
    private func structuredResultView(_ result: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(result.extractionMode.rawValue, systemImage: result.extractionMode.icon)
                    .font(.subheadline.bold())
                    .foregroundColor(.accentColor)
                Spacer()
                Text(result.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let summary = result.summaryResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text(summary.title)
                        .font(.headline)
                    Text(summary.body)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let points = result.keyPoints {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(points.enumerated()), id: \.offset) { idx, point in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(idx + 1).")
                                .font(.caption.bold())
                                .foregroundColor(.accentColor)
                                .frame(width: 20, alignment: .trailing)
                            Text(point)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let items = result.actionItems {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items) { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(item.isCompleted ? .green : .secondary)
                            Text(item.title)
                                .font(.subheadline)
                                .strikethrough(item.isCompleted)
                            if let due = item.dueDate {
                                Spacer()
                                Text(due)
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let cards = result.flashcards {
                VStack(spacing: 10) {
                    ForEach(cards) { card in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                Text(card.question)
                                    .font(.subheadline.bold())
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(card.answer)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private var detectedStructuresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Detected Structures", systemImage: "doc.text.below.ecg")
                .font(.subheadline.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(engine.detectedStructures) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.kind.icon)
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                            Text(item.kind.rawValue)
                                .font(.caption2.weight(.medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(.separator).opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - Step 3: AI Tools

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

    // MARK: - Step 4: Chat ("Ask Anything About This")

    private var chatStepView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ask Anything About This")
                    .font(.title2.bold())
                Spacer()
                if let scanID = viewModel.activeScanID ?? engine.structuredResult?.id {
                    let related = engine.linkedScans(for: scanID)
                    if !related.isEmpty {
                        Label("\(related.count) linked", systemImage: "link")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text("Chat with AI about your scanned content. Context is preserved across messages.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if engine.activeChatMessages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("Start a conversation about your scan")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(engine.activeChatMessages) { message in
                                chatBubble(message)
                                    .id(message.id)
                            }
                        }

                        if engine.isChatProcessing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .id("typing")
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 400)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                )
                .onChange(of: engine.activeChatMessages.count) { _ in
                    if let last = engine.activeChatMessages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Chat input
            HStack(spacing: 8) {
                TextField("Ask about this scan...", text: $viewModel.chatInput)
                    .textFieldStyle(.roundedBorder)

                Button {
                    let scanID = viewModel.activeScanID ?? engine.structuredResult?.id ?? UUID()
                    if viewModel.activeScanID == nil {
                        viewModel.activeScanID = scanID
                        engine.startChatSession(for: scanID)
                    }
                    let text = viewModel.chatInput
                    viewModel.chatInput = ""
                    engine.sendChatMessage(text, scanID: scanID)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .disabled(viewModel.chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || engine.isChatProcessing)
            }

            // Quick question suggestions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    quickChatButton("Summarize key findings")
                    quickChatButton("What are the main topics?")
                    quickChatButton("Find action items")
                    quickChatButton("Explain the key terms")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            let scanID = viewModel.activeScanID ?? engine.structuredResult?.id
            if let sid = scanID {
                engine.startChatSession(for: sid)
            }
        }
    }

    private func chatBubble(_ message: ScanChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer() }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                            ? Color.accentColor
                            : Color(.tertiarySystemBackground)
                    )
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)

            if message.role != .user { Spacer() }
        }
        .padding(.horizontal, 8)
    }

    private func quickChatButton(_ text: String) -> some View {
        Button {
            viewModel.chatInput = text
        } label: {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(.separator).opacity(0.3), lineWidth: 1))
        }
        .foregroundColor(.primary)
    }

    // MARK: - Step 5: Transform

    private var transformStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Transform")
                .font(.title2.bold())

            Text("Convert your scanned content into other formats and integrate with your workspace.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(ScanTransformTarget.allCases) { target in
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.selectedTransformTarget = target
                        let scanID = viewModel.activeScanID ?? engine.structuredResult?.id ?? UUID()
                        engine.transformScan(scanID: scanID, target: target)
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: target.icon)
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            Text(target.rawValue)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                        )
                    }
                    .foregroundColor(.primary)
                    .disabled(engine.isTransforming || engine.extractedText.isEmpty)
                }
            }

            if let result = engine.transformResult {
                transformResultView(result)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func transformResultView(_ result: ScanTransformResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(result.target.rawValue, systemImage: result.target.icon)
                    .font(.headline)
                    .foregroundColor(.accentColor)
                Spacer()
                Text(result.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ScrollView {
                Text(result.content)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
            )

            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = result.content
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)

                Button {
                    let scanID = viewModel.activeScanID ?? engine.structuredResult?.id ?? UUID()
                    engine.applyTransformToWorkspace(result: result, scanID: scanID)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } label: {
                    Label("Add to Workspace", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
        }
    }

    // MARK: - Step 6: History

    private var historyStepView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scan History")
                .font(.title2.bold())

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search scans...", text: $viewModel.historySearchQuery)
                    .textFieldStyle(.roundedBorder)
            }

            // Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ScanHistoryFilter.allCases) { filter in
                        Button {
                            viewModel.historyFilter = filter
                        } label: {
                            Text(filter.rawValue)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    viewModel.historyFilter == filter
                                        ? Color.accentColor
                                        : Color(.tertiarySystemBackground)
                                )
                                .foregroundColor(viewModel.historyFilter == filter ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            let results = viewModel.historySearchQuery.isEmpty
                ? engine.filteredHistory(filter: viewModel.historyFilter)
                : engine.searchHistory(query: viewModel.historySearchQuery)

            if results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No scans found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(results) { scan in
                        scanHistoryRow(scan)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func scanHistoryRow(_ scan: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: scan.extractionMode.icon)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                Text(scan.displayTitle)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                Text(scan.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(scan.rawText.prefix(120) + (scan.rawText.count > 120 ? "…" : ""))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if !scan.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(scan.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.activeScanID = scan.id
                    engine.startChatSession(for: scan.id)
                    transitionToStep(.chat)
                } label: {
                    Label("Chat", systemImage: "bubble.left")
                        .font(.caption2.bold())
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)

                Button {
                    viewModel.activeScanID = scan.id
                    transitionToStep(.transform)
                } label: {
                    Label("Transform", systemImage: "arrow.triangle.branch")
                        .font(.caption2.bold())
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)

                Spacer()

                Button(role: .destructive) {
                    engine.deleteScan(scan)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - History Sheet

    private var scanHistorySheet: some View {
        NavigationStack {
            historyStepView
                .padding()
                .navigationTitle("Scan History")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showHistorySheet = false }
                    }
                }
        }
    }

    // MARK: - Transform Sheet

    private var transformSheet: some View {
        NavigationStack {
            transformStepView
                .padding()
                .navigationTitle("Transform Scan")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { viewModel.showTransformSheet = false }
                    }
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

            if viewModel.currentStep == .capture || viewModel.currentStep == .review {
                Button {
                    let next = ScanStep(rawValue: viewModel.currentStep.rawValue + 1) ?? .review
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
        default:       return "Next"
        }
    }

    private var canAdvance: Bool {
        switch viewModel.currentStep {
        case .capture:
            return !engine.extractedText.isEmpty
        case .review:
            return !engine.extractedText.isEmpty
        default:
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
