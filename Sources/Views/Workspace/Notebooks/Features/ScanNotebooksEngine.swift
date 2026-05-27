import SwiftUI
import AVFoundation
@preconcurrency import Vision

// MARK: - Scan Engine

@MainActor
final class ScanNotebooksEngine: NSObject, ObservableObject {

    // MARK: Published state — Camera & OCR

    @Published var isCameraReady = false
    @Published var isCapturing = false
    @Published var capturedImage: UIImage?
    @Published var extractedText = ""
    @Published var extractionError: String?
    @Published var isExtracting = false
    @Published var cameraPermissionDenied = false

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
        qualityIssues = []
        unreadableRegions = []
        ocrConfidence = 1.0
        structuredResult = nil
        detectedStructures = []

        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    // MARK: - Text Extraction (Vision) with Quality Analysis

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

                self.extractedText = lines.joined(separator: "\n")

                var totalConfidence: Float = 0
                var count: Float = 0
                var lowConfRegions: [CGRect] = []

                for obs in observations {
                    if let candidate = obs.topCandidates(1).first {
                        totalConfidence += candidate.confidence
                        count += 1
                        if candidate.confidence < 0.5 {
                            lowConfRegions.append(obs.boundingBox)
                        }
                    }
                }

                self.ocrConfidence = count > 0 ? Double(totalConfidence / count) : 0
                self.unreadableRegions = lowConfRegions

                if self.ocrConfidence < 0.6 {
                    self.qualityIssues.append(.blur)
                }

                self.detectStructures(in: self.extractedText)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Image Quality Analysis

    private func analyzeImageQuality(_ cgImage: CGImage) {
        let width = cgImage.width
        let height = cgImage.height

        if width < 640 || height < 480 {
            qualityIssues.append(.partial)
        }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let laplacianVariance = self.map { engine in
                Task { @MainActor in
                    engine.computeLaplacianVariance(cgImage)
                }
            }
            Task { @MainActor in
                let variance = await laplacianVariance?.value ?? 100
                if variance < 50 {
                    self?.qualityIssues.append(.blur)
                }
            }
        }

        let brightnessRequest = VNGenerateImageFeaturePrintRequest()
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([brightnessRequest])
            let avgBrightness = self.map { engine in
                Task { @MainActor in
                    engine.estimateBrightness(cgImage)
                }
            }
            Task { @MainActor in
                let brightness = await avgBrightness?.value ?? 128
                if brightness < 60 {
                    self?.qualityIssues.append(.lowLight)
                }
            }
        }
    }

    private func computeLaplacianVariance(_ cgImage: CGImage) -> Double {
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 100 }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        guard width > 2, height > 2 else { return 100 }

        var sum: Double = 0
        var sumSq: Double = 0
        var count: Double = 0

        let step = max(1, min(width, height) / 100)

        for y in stride(from: 1, to: height - 1, by: step) {
            for x in stride(from: 1, to: width - 1, by: step) {
                let idx = y * bytesPerRow + x * bytesPerPixel
                let center = Double(ptr[idx])
                let top = Double(ptr[(y - 1) * bytesPerRow + x * bytesPerPixel])
                let bottom = Double(ptr[(y + 1) * bytesPerRow + x * bytesPerPixel])
                let left = Double(ptr[y * bytesPerRow + (x - 1) * bytesPerPixel])
                let right = Double(ptr[y * bytesPerRow + (x + 1) * bytesPerPixel])
                let laplacian = top + bottom + left + right - 4 * center
                sum += laplacian
                sumSq += laplacian * laplacian
                count += 1
            }
        }

        guard count > 0 else { return 100 }
        let mean = sum / count
        return (sumSq / count) - (mean * mean)
    }

    private func estimateBrightness(_ cgImage: CGImage) -> Double {
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 128 }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        var total: Double = 0
        var count: Double = 0
        let step = max(1, min(width, height) / 50)

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let idx = y * bytesPerRow + x * bytesPerPixel
                let r = Double(ptr[idx])
                let g = bytesPerPixel > 1 ? Double(ptr[idx + 1]) : r
                let b = bytesPerPixel > 2 ? Double(ptr[idx + 2]) : r
                total += 0.299 * r + 0.587 * g + 0.114 * b
                count += 1
            }
        }

        return count > 0 ? total / count : 128
    }

    // MARK: - Structure Detection

    private func detectStructures(in text: String) {
        let lines = text.components(separatedBy: "\n")
        var structures: [DetectedStructureItem] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.contains("\t") || trimmed.contains(" | ") || trimmed.filter({ $0 == "|" }).count >= 2 {
                structures.append(DetectedStructureItem(kind: .table, rawText: trimmed, lineRange: index...index))
            }

            if trimmed.hasPrefix("☐") || trimmed.hasPrefix("☑") || trimmed.hasPrefix("☒")
                || trimmed.hasPrefix("[ ]") || trimmed.hasPrefix("[x]") || trimmed.hasPrefix("[X]")
                || trimmed.hasPrefix("□") || trimmed.hasPrefix("✓") || trimmed.hasPrefix("✗") {
                structures.append(DetectedStructureItem(kind: .checklist, rawText: trimmed, lineRange: index...index))
            }

            let datePattern = #"\b\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}\b"#
            let isoPattern = #"\b\d{4}-\d{2}-\d{2}\b"#
            let wordDatePattern = #"\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \d{1,2},? \d{4}\b"#
            if trimmed.range(of: datePattern, options: .regularExpression) != nil
                || trimmed.range(of: isoPattern, options: .regularExpression) != nil
                || trimmed.range(of: wordDatePattern, options: .regularExpression) != nil {
                structures.append(DetectedStructureItem(kind: .date, rawText: trimmed, lineRange: index...index))
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") || trimmed.hasPrefix("* ") {
                structures.append(DetectedStructureItem(kind: .list, rawText: trimmed, lineRange: index...index))
            }

            let eqPattern = #"[=+\-*/^]"#
            if (trimmed.contains("=") && trimmed.range(of: #"\d+\s*[+\-*/^]\s*\d+"#, options: .regularExpression) != nil)
                || trimmed.range(of: eqPattern, options: .regularExpression) != nil && trimmed.filter({ $0.isNumber }).count > trimmed.count / 2 {
                structures.append(DetectedStructureItem(kind: .equation, rawText: trimmed, lineRange: index...index))
            }
        }

        detectedStructures = structures
    }

    // MARK: - Structured Extraction (AI)

    func performStructuredExtraction(mode: ScanExtractionMode) {
        guard !extractedText.isEmpty else { return }
        isProcessingStructured = true

        Task {
            do {
                let prompt = "\(mode.prompt)\n\nScanned text:\n\(extractedText)"
                let result = try await aiService.processText(
                    prompt: prompt,
                    systemPrompt: mode.systemPrompt
                )

                var scan = ScanResult(
                    rawText: extractedText,
                    extractionMode: mode,
                    detectedStructures: detectedStructures,
                    imageData: capturedImage?.jpegData(compressionQuality: 0.6),
                    tags: detectedStructures.map { $0.kind.rawValue }
                )

                switch mode {
                case .fullText:
                    scan.summaryResult = ScanSummaryResult(title: "Full Text", body: result)
                case .summary:
                    if let data = result.data(using: .utf8),
                       let decoded = try? JSONDecoder().decode(ScanSummaryResult.self, from: data) {
                        scan.summaryResult = decoded
                    } else {
                        scan.summaryResult = ScanSummaryResult(title: "Summary", body: result)
                    }
                case .keyPoints:
                    if let data = result.data(using: .utf8),
                       let decoded = try? JSONDecoder().decode([String].self, from: data) {
                        scan.keyPoints = decoded
                    } else {
                        scan.keyPoints = result.components(separatedBy: "\n").filter { !$0.isEmpty }
                    }
                case .actionItems:
                    if let data = result.data(using: .utf8),
                       let decoded = try? JSONDecoder().decode([ScanActionItem].self, from: data) {
                        scan.actionItems = decoded
                    } else {
                        scan.actionItems = result.components(separatedBy: "\n")
                            .filter { !$0.isEmpty }
                            .map { ScanActionItem(title: $0) }
                    }
                case .flashcards:
                    if let data = result.data(using: .utf8),
                       let decoded = try? JSONDecoder().decode([ScanFlashcard].self, from: data) {
                        scan.flashcards = decoded
                    } else {
                        scan.flashcards = [ScanFlashcard(question: "Review", answer: result)]
                    }
                }

                structuredResult = scan
                addToHistory(scan)
                isProcessingStructured = false
            } catch {
                extractionError = "Structured extraction failed: \(error.localizedDescription)"
                isProcessingStructured = false
            }
        }
    }

    // MARK: - Persistent Context Layer

    private func addToHistory(_ scan: ScanResult) {
        scanHistory.insert(scan, at: 0)
        scanIndex[scan.id] = scan
        saveHistory()
    }

    func deleteScan(_ scan: ScanResult) {
        scanHistory.removeAll { $0.id == scan.id }
        scanIndex.removeValue(forKey: scan.id)
        chatSessions.removeValue(forKey: scan.id)
        saveHistory()
        saveChatSessions()
    }

    func searchHistory(query: String) -> [ScanResult] {
        guard !query.isEmpty else { return scanHistory }
        let lowered = query.lowercased()
        return scanHistory.filter { scan in
            scan.rawText.lowercased().contains(lowered)
            || scan.displayTitle.lowercased().contains(lowered)
            || scan.tags.contains(where: { $0.lowercased().contains(lowered) })
        }
    }

    func filteredHistory(filter: ScanHistoryFilter) -> [ScanResult] {
        let calendar = Calendar.current
        let now = Date()
        switch filter {
        case .all:
            return scanHistory
        case .today:
            return scanHistory.filter { calendar.isDateInToday($0.createdAt) }
        case .thisWeek:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return scanHistory.filter { $0.createdAt >= weekAgo }
        case .thisMonth:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return scanHistory.filter { $0.createdAt >= monthAgo }
        }
    }

    func linkedScans(for scanID: UUID) -> [ScanResult] {
        guard let scan = scanIndex[scanID] else { return [] }
        return scanHistory.filter { other in
            guard other.id != scanID else { return false }
            let sharedTags = Set(scan.tags).intersection(Set(other.tags))
            return !sharedTags.isEmpty
        }
    }

    // MARK: - Chat System (per-scan, multi-turn)

    func startChatSession(for scanID: UUID) {
        if chatSessions[scanID] == nil {
            chatSessions[scanID] = ScanChatSession(scanID: scanID)
        }
        activeChatMessages = chatSessions[scanID]?.messages ?? []
    }

    func sendChatMessage(_ text: String, scanID: UUID) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ScanChatMessage(role: .user, content: text)
        chatSessions[scanID]?.messages.append(userMessage)
        activeChatMessages = chatSessions[scanID]?.messages ?? []
        isChatProcessing = true

        Task {
            do {
                let scanContext = scanIndex[scanID]?.rawText ?? extractedText
                let linked = linkedScans(for: scanID)
                var contextBlock = "Scanned text:\n\(scanContext)"
                if !linked.isEmpty {
                    contextBlock += "\n\nRelated scans:\n"
                    for related in linked.prefix(3) {
                        contextBlock += "---\n\(related.rawText.prefix(500))\n"
                    }
                }

                let history = (chatSessions[scanID]?.messages ?? [])
                    .filter { $0.role != .system }
                    .map { "\($0.role.rawValue): \($0.content)" }
                    .joined(separator: "\n")

                let prompt = """
                Context:
                \(contextBlock)

                Conversation history:
                \(history)

                User question: \(text)
                """

                let systemPrompt = "You are a knowledgeable assistant helping analyze scanned document content. Answer questions based on the provided scanned text and any related scans. Be precise and helpful. If asked about something not in the documents, say so."

                let response = try await aiService.processText(
                    prompt: prompt,
                    systemPrompt: systemPrompt
                )

                let assistantMessage = ScanChatMessage(role: .assistant, content: response)
                chatSessions[scanID]?.messages.append(assistantMessage)
                activeChatMessages = chatSessions[scanID]?.messages ?? []
                isChatProcessing = false
                saveChatSessions()
            } catch {
                let errorMessage = ScanChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)")
                chatSessions[scanID]?.messages.append(errorMessage)
                activeChatMessages = chatSessions[scanID]?.messages ?? []
                isChatProcessing = false
            }
        }
    }

    // MARK: - Transform Pipeline

    func transformScan(scanID: UUID, target: ScanTransformTarget) {
        guard let scan = scanIndex[scanID] ?? structuredResult else { return }
        isTransforming = true
        transformResult = nil

        Task {
            do {
                let prompt = "\(target.prompt)\n\nScanned content:\n\(scan.rawText)"
                let result = try await aiService.processText(
                    prompt: prompt,
                    systemPrompt: target.systemPrompt
                )

                transformResult = ScanTransformResult(
                    target: target,
                    content: result
                )
                isTransforming = false
            } catch {
                transformResult = ScanTransformResult(
                    target: target,
                    content: "Transform failed: \(error.localizedDescription)"
                )
                isTransforming = false
            }
        }
    }

    func applyTransformToWorkspace(result: ScanTransformResult, scanID: UUID) {
        let manager = NotebooksManager.shared
        let scan = scanIndex[scanID] ?? structuredResult

        switch result.target {
        case .note:
            let nb = manager.createNotebook(name: scan?.displayTitle ?? "Scanned Note")
            if let folder = manager.addFolder(to: nb.id, name: "Scanned Content") {
                manager.addPage(to: folder.id, in: nb.id, title: "Scan Result", content: result.content)
            }

        case .tasks:
            if let data = result.content.data(using: .utf8),
               let tasks = try? JSONDecoder().decode([[String: String]].self, from: data) {
                let nb = manager.createNotebook(name: "Tasks from Scan")
                if let folder = manager.addFolder(to: nb.id, name: "Tasks") {
                    for task in tasks {
                        let title = task["title"] ?? "Task"
                        let desc = task["description"] ?? ""
                        manager.addPage(to: folder.id, in: nb.id, title: title, content: desc)
                    }
                }
            }

        case .presentation:
            let nb = manager.createNotebook(name: "Presentation from Scan")
            if let folder = manager.addFolder(to: nb.id, name: "Slides") {
                manager.addPage(to: folder.id, in: nb.id, title: "Presentation", content: result.content)
            }

        case .report:
            let nb = manager.createNotebook(name: scan?.displayTitle ?? "Report")
            if let folder = manager.addFolder(to: nb.id, name: "Report") {
                manager.addPage(to: folder.id, in: nb.id, title: "Full Report", content: result.content)
            }

        case .spreadsheet, .calendarEvent:
            let nb = manager.createNotebook(name: "\(result.target.rawValue) from Scan")
            if let folder = manager.addFolder(to: nb.id, name: result.target.rawValue) {
                manager.addPage(to: folder.id, in: nb.id, title: result.target.rawValue, content: result.content)
            }
        }
    }

    // MARK: - Persistence (History & Chat)

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(scanHistory)
            try data.write(to: historyURL)
        } catch {
            print("[ScanEngine] Failed to save history: \(error)")
        }
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL),
              let decoded = try? JSONDecoder().decode([ScanResult].self, from: data) else { return }
        scanHistory = decoded
        scanIndex = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
    }

    private func saveChatSessions() {
        do {
            let sessionsArray = Array(chatSessions.values)
            let data = try JSONEncoder().encode(sessionsArray)
            try data.write(to: chatURL)
        } catch {
            print("[ScanEngine] Failed to save chat sessions: \(error)")
        }
    }

    private func loadChatSessions() {
        guard let data = try? Data(contentsOf: chatURL),
              let decoded = try? JSONDecoder().decode([ScanChatSession].self, from: data) else { return }
        chatSessions = Dictionary(uniqueKeysWithValues: decoded.map { ($0.scanID, $0) })
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
