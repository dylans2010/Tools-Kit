import SwiftUI
import AVFoundation
import Vision
import CoreImage

// MARK: - Scan Engine

@MainActor
final class ScanNotebooksEngine: NSObject, ObservableObject {

    // MARK: Published state — camera

    @Published var isCameraReady = false
    @Published var isCapturing = false
    @Published var capturedImage: UIImage?
    @Published var cameraPermissionDenied = false

    // MARK: Published state — extraction

    @Published var extractedText = ""
    @Published var extractionError: String?
    @Published var isExtracting = false
    @Published var selectedMode: ScanExtractionMode = .fullText
    @Published var extractionResult: ScanExtractionResult?
    @Published var isProcessingMode = false

    // MARK: Published state — quality & regions

    @Published var qualityFeedback = ScanQualityFeedback()
    @Published var unreadableRegions: [ScanUnreadableRegion] = []

    // MARK: Published state — structured data detection

    @Published var detectedData: [ScanDetectedData] = []

    // MARK: Published state — chat

    @Published var chatMessages: [ScanChatMessage] = []
    @Published var isChatLoading = false

    // MARK: Published state — transform

    @Published var transformResult: String?
    @Published var isTransforming = false

    // MARK: Published state — persistent context

    @Published var currentRecord: ScanRecord?

    // MARK: Dependencies

    let contextStore = ScanContextStore.shared

    // MARK: Published state — Structured extraction

    @Published var selectedExtractionMode: ScanExtractionMode = .fullText
    @Published var structuredResult: ScanResult?
    @Published var isProcessingStructured = false

    // MARK: Published state — Quality feedback

    @Published var qualityIssues: [ScanQualityIssue] = []
    @Published var unreadableRegions: [CGRect] = []
    @Published var ocrConfidence: Double = 1.0

    // MARK: Published state — Context layer (persistent scans)

    @Published var scanHistory: [ScanResult] = []
    @Published var scanIndex: [UUID: ScanResult] = [:]

    // MARK: Published state — Chat

    @Published var chatSessions: [UUID: ScanChatSession] = [:]
    @Published var activeChatMessages: [ScanChatMessage] = []
    @Published var isChatProcessing = false

    // MARK: Published state — Transform

    @Published var transformResult: ScanTransformResult?
    @Published var isTransforming = false

    // MARK: Published state — Detected structures

    @Published var detectedStructures: [DetectedStructureItem] = []

    // MARK: AVFoundation objects

    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "com.toolskit.scan.video", qos: .userInitiated)
    private var lastQualityCheck: Date = .distantPast

    // MARK: Persistence

    private let aiService = AIService.shared

    private var storageURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("ScanNotebooks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var historyURL: URL { storageURL.appendingPathComponent("scan_history.json") }
    private var chatURL: URL { storageURL.appendingPathComponent("chat_sessions.json") }

    // MARK: - Init

    override init() {
        super.init()
        loadHistory()
        loadChatSessions()
    }

    // MARK: - Camera Lifecycle

    func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.cameraPermissionDenied = true
                    }
                }
            }
        default:
            cameraPermissionDenied = true
        }
    }

    private func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()
        currentDevice = device

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            Task { @MainActor in
                self?.isCameraReady = true
            }
        }
    }

    // MARK: - Capture

    func capturePhoto() {
        guard isCameraReady else { return }
        isCapturing = true
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func retryCapture() {
        capturedImage = nil
        extractedText = ""
        extractionError = nil
        isExtracting = false
        extractionResult = nil
        isProcessingMode = false
        qualityFeedback = ScanQualityFeedback()
        unreadableRegions = []
        detectedData = []
        chatMessages = []
        transformResult = nil
        currentRecord = nil

        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    // MARK: - Text extraction (Vision) with structured modes

    func extractText(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            extractionError = "Could not process image."
            return
        }

        isExtracting = true
        extractionError = nil
        qualityIssues = []
        unreadableRegions = []

        analyzeImageQuality(cgImage)

        let request = VNRecognizeTextRequest { [weak self] request, error in
            Task { @MainActor in
                guard let self else { return }
                self.isExtracting = false

                if let error {
                    self.extractionError = error.localizedDescription
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.extractionError = "No text found in image."
                    return
                }

                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                if lines.isEmpty {
                    self.extractionError = "No text found in image."
                    return
                }

                let fullText = lines.joined(separator: "\n")
                self.extractedText = fullText

                self.findUnreadableRegions(observations: observations, imageSize: image.size)
                self.detectStructuredData(in: fullText)

                await self.processExtractionMode(rawText: fullText)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Extraction mode processing

    func processExtractionMode(rawText: String) async {
        let mode = selectedMode

        if mode == .fullText {
            extractionResult = .fullText(rawText)
            saveScanRecord()
            return
        }

        isProcessingMode = true
        do {
            let prompt = "\(mode.userPrompt)\n\n\(rawText)"
            let response = try await AIService.shared.processText(
                prompt: prompt,
                systemPrompt: mode.systemPrompt
            )
            let result = parseExtractionResult(mode: mode, response: response, rawText: rawText)
            extractionResult = result
            saveScanRecord()
        } catch {
            extractionResult = .fullText(rawText)
        }
        isProcessingMode = false
    }

    func reprocessWithMode(_ mode: ScanExtractionMode) {
        guard !extractedText.isEmpty else { return }
        selectedMode = mode
        Task {
            await processExtractionMode(rawText: extractedText)
        }
    }

    private func parseExtractionResult(mode: ScanExtractionMode, response: String, rawText: String) -> ScanExtractionResult {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        switch mode {
        case .fullText:
            return .fullText(rawText)
        case .summary:
            return .summary(trimmed)
        case .keyPoints:
            if let data = trimmed.data(using: .utf8),
               let points = try? JSONDecoder().decode([String].self, from: data) {
                return .keyPoints(points)
            }
            let lines = trimmed.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { $0.hasPrefix("•") || $0.hasPrefix("-") ? String($0.dropFirst()).trimmingCharacters(in: .whitespaces) : $0 }
            return .keyPoints(lines)
        case .actionItems:
            if let data = trimmed.data(using: .utf8),
               let items = try? JSONDecoder().decode([ScanActionItem].self, from: data) {
                return .actionItems(items)
            }
            let lines = trimmed.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return .actionItems(lines.map { ScanActionItem(task: $0) })
        case .flashcards:
            if let data = trimmed.data(using: .utf8),
               let cards = try? JSONDecoder().decode([ScanFlashcard].self, from: data) {
                return .flashcards(cards)
            }
            return .flashcards([ScanFlashcard(question: "Review", answer: trimmed)])
        }
    }

    // MARK: - Unreadable region detection

    private func findUnreadableRegions(observations: [VNRecognizedTextObservation], imageSize: CGSize) {
        var regions: [ScanUnreadableRegion] = []
        for obs in observations {
            guard let candidate = obs.topCandidates(1).first else {
                let box = obs.boundingBox
                let rect = CGRect(
                    x: box.origin.x * imageSize.width,
                    y: (1 - box.origin.y - box.height) * imageSize.height,
                    width: box.width * imageSize.width,
                    height: box.height * imageSize.height
                )
                regions.append(ScanUnreadableRegion(boundingBox: rect, reason: "No text recognized"))
                continue
            }
            if candidate.confidence < 0.5 {
                let box = obs.boundingBox
                let rect = CGRect(
                    x: box.origin.x * imageSize.width,
                    y: (1 - box.origin.y - box.height) * imageSize.height,
                    width: box.width * imageSize.width,
                    height: box.height * imageSize.height
                )
                regions.append(ScanUnreadableRegion(boundingBox: rect, reason: "Low confidence (\(Int(candidate.confidence * 100))%)"))
            }
        }
        unreadableRegions = regions
    }

    // MARK: - Structured data detection

    private func detectStructuredData(in text: String) {
        var detected: [ScanDetectedData] = []

        let dateDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let phoneDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)

        let range = NSRange(text.startIndex..., in: text)

        dateDetector?.enumerateMatches(in: text, range: range) { match, _, _ in
            if let match, let r = Range(match.range, in: text) {
                detected.append(ScanDetectedData(kind: .date, rawText: String(text[r])))
            }
        }

        linkDetector?.enumerateMatches(in: text, range: range) { match, _, _ in
            if let match, let r = Range(match.range, in: text) {
                let raw = String(text[r])
                if raw.contains("@") {
                    detected.append(ScanDetectedData(kind: .email, rawText: raw))
                } else {
                    detected.append(ScanDetectedData(kind: .url, rawText: raw))
                }
            }
        }

        phoneDetector?.enumerateMatches(in: text, range: range) { match, _, _ in
            if let match, let r = Range(match.range, in: text) {
                detected.append(ScanDetectedData(kind: .phoneNumber, rawText: String(text[r])))
            }
        }

        let lines = text.components(separatedBy: .newlines)
        let checklistPattern = lines.filter {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("☐") ||
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("☑") ||
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("[ ]") ||
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("[x]") ||
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("[X]") ||
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("- [ ]") ||
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("- [x]")
        }
        if !checklistPattern.isEmpty {
            detected.append(ScanDetectedData(kind: .checklist, rawText: checklistPattern.joined(separator: "\n")))
        }

        let tableLines = lines.filter { $0.contains("|") || $0.contains("\t") }
        if tableLines.count >= 2 {
            detected.append(ScanDetectedData(kind: .table, rawText: tableLines.joined(separator: "\n")))
        }

        detectedData = detected
    }

    // MARK: - Real-time quality analysis

    nonisolated func analyzeFrameQuality(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        var isBlurry = false
        var isLowLight = false

        let extent = ciImage.extent
        let inputImage = ciImage.clampedToExtent()
        let avgFilter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: inputImage,
            kCIInputExtentKey: CIVector(cgRect: extent)
        ])

        if let outputImage = avgFilter?.outputImage {
            var bitmap = [UInt8](repeating: 0, count: 4)
            let context = CIContext(options: [.workingColorSpace: NSNull()])
            context.render(outputImage,
                          toBitmap: &bitmap,
                          rowBytes: 4,
                          bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                          format: .RGBA8,
                          colorSpace: nil)
            let luminance = (0.299 * Double(bitmap[0]) + 0.587 * Double(bitmap[1]) + 0.114 * Double(bitmap[2])) / 255.0
            isLowLight = luminance < 0.15
        }

        let laplacian = CIFilter(name: "CIConvolution3X3", parameters: [
            kCIInputImageKey: ciImage,
            "inputWeights": CIVector(values: [0, 1, 0, 1, -4, 1, 0, 1, 0], count: 9),
            "inputBias": 0
        ])
        if let lapOutput = laplacian?.outputImage {
            let statsFilter = CIFilter(name: "CIAreaAverage", parameters: [
                kCIInputImageKey: lapOutput.clampedToExtent(),
                kCIInputExtentKey: CIVector(cgRect: extent)
            ])
            if let statsOutput = statsFilter?.outputImage {
                var bitmap = [UInt8](repeating: 0, count: 4)
                let context = CIContext(options: [.workingColorSpace: NSNull()])
                context.render(statsOutput,
                              toBitmap: &bitmap,
                              rowBytes: 4,
                              bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                              format: .RGBA8,
                              colorSpace: nil)
                let variance = Double(bitmap[0])
                isBlurry = variance < 15
            }
        }

        let score = max(0, min(1, 1.0 - (isBlurry ? 0.4 : 0) - (isLowLight ? 0.4 : 0)))

        Task { @MainActor [isBlurry, isLowLight, score] in
            self.qualityFeedback = ScanQualityFeedback(
                isBlurry: isBlurry,
                isLowLight: isLowLight,
                overallScore: score
            )
        }
    }

    // MARK: - Chat system ("Ask Anything About This")

    func sendChatMessage(_ userMessage: String) {
        guard !userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMsg = ScanChatMessage(role: .user, content: userMessage)
        chatMessages.append(userMsg)
        isChatLoading = true

        let contextSummary = buildChatContext()

        Task {
            do {
                let prompt = """
                The user is asking about scanned content. Here is the context:

                --- SCANNED TEXT ---
                \(extractedText)

                --- PREVIOUS CONVERSATION ---
                \(contextSummary)

                --- USER QUESTION ---
                \(userMessage)
                """

                let response = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: "You are a helpful assistant that answers questions about scanned documents. Use the scanned text and conversation history to provide accurate, contextual answers. Be concise and specific."
                )
                let assistantMsg = ScanChatMessage(role: .assistant, content: response)
                chatMessages.append(assistantMsg)
                updateRecordChat()
            } catch {
                let errorMsg = ScanChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)")
                chatMessages.append(errorMsg)
            }
            isChatLoading = false
        }
    }

    private func buildChatContext() -> String {
        chatMessages.map { msg in
            let role = msg.role == .user ? "User" : "Assistant"
            return "\(role): \(msg.content)"
        }.joined(separator: "\n")
    }

    func sendFollowUpAcrossScans(_ question: String, linkedRecordIDs: [UUID]) {
        let linkedTexts = linkedRecordIDs.compactMap { contextStore.record(for: $0) }
            .map { "[\($0.timestamp.formatted())]: \($0.rawText)" }
            .joined(separator: "\n\n")

        let userMsg = ScanChatMessage(role: .user, content: question)
        chatMessages.append(userMsg)
        isChatLoading = true

        Task {
            do {
                let prompt = """
                The user is asking a follow-up question that spans multiple scanned documents.

                --- CURRENT SCAN ---
                \(extractedText)

                --- LINKED SCANS ---
                \(linkedTexts)

                --- QUESTION ---
                \(question)
                """

                let response = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: "You are a helpful assistant that reasons across multiple scanned documents. Synthesize information from all provided scans to answer accurately."
                )
                let assistantMsg = ScanChatMessage(role: .assistant, content: response)
                chatMessages.append(assistantMsg)
                updateRecordChat()
            } catch {
                let errorMsg = ScanChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)")
                chatMessages.append(errorMsg)
            }
            isChatLoading = false
        }
    }

    // MARK: - Transform pipeline

    func transformScan(to format: ScanTransformFormat) {
        guard !extractedText.isEmpty else { return }
        isTransforming = true
        transformResult = nil

        Task {
            do {
                let prompt = "Transform the following scanned content:\n\n\(extractedText)"
                let response = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: format.systemPrompt
                )
                transformResult = response
            } catch {
                transformResult = "Error: \(error.localizedDescription)"
            }
            isTransforming = false
        }
    }

    // MARK: - Persistent context management

    private func saveScanRecord() {
        guard let result = extractionResult else { return }

        let previousIDs = contextStore.records.prefix(5).map { $0.id }

        let record = ScanRecord(
            rawText: extractedText,
            extractionMode: selectedMode,
            result: result,
            detectedData: detectedData,
            chatMessages: chatMessages,
            linkedScanIDs: Array(previousIDs)
        )
        contextStore.addRecord(record)
        currentRecord = record
    }

    private func updateRecordChat() {
        guard var record = currentRecord else { return }
        record.chatMessages = chatMessages
        contextStore.updateRecord(record)
        currentRecord = record
    }

    // MARK: - Cleanup

    func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension ScanNotebooksEngine: AVCapturePhotoCaptureDelegate {

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        Task { @MainActor in
            isCapturing = false

            if let error {
                extractionError = error.localizedDescription
                return
            }

            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else {
                extractionError = "Failed to process captured photo."
                return
            }

            capturedImage = image

            captureSession.stopRunning()

            extractText(from: image)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ScanNotebooksEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        let now = Date()
        let lastCheck = DispatchQueue.main.sync { self.lastQualityCheck }
        guard now.timeIntervalSince(lastCheck) > 0.5 else { return }
        Task { @MainActor in
            self.lastQualityCheck = now
        }
        analyzeFrameQuality(sampleBuffer)
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
