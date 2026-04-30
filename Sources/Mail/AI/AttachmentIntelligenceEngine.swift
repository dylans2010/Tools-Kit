import Foundation
import UIKit

/// Engine for file-type classification, OCR, and structured data extraction from attachments.
actor AttachmentIntelligenceEngine {
    static let shared = AttachmentIntelligenceEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Analyzes an attachment and extracts insights.
    func analyzeAttachment(_ attachment: MailMessage.MailAttachment, content: Data) async throws -> AttachmentIntelligence {
        let fileType = classifyFileType(fileName: attachment.fileName)
        var intel = AttachmentIntelligence(id: attachment.id, fileName: attachment.fileName, fileType: fileType)

        // OCR logic if applicable
        if fileType == .document || fileType == .contract || fileType == .receipt {
            intel.ocrText = try? await performOCR(on: content)
            if let ocr = intel.ocrText {
                intel.extractedData = try? await extractStructuredData(from: ocr, type: fileType)
                intel.summary = try? await aiService.summarize(text: ocr)
            }
        }

        return intel
    }

    private func classifyFileType(fileName: String) -> AttachmentIntelligence.AttachmentType {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf", "docx", "txt": return .document
        case "jpg", "png", "heic": return .media
        case "swift", "py", "js", "ts", "json": return .code
        case "csv", "xlsx": return .dataset
        default: return .unknown
        }
    }

    private func performOCR(on data: Data) async throws -> String {
        // We use a @MainActor-isolated closure to safely handle the non-Sendable UIImage
        // ensuring it never actually crosses actor boundaries during concurrent execution.
        return try await MainActor.run {
            guard let image = UIImage(data: data) else { return "" }
            return try await VisionService.shared.performOCR(on: image)
        }
    }

    private func extractStructuredData(from text: String, type: AttachmentIntelligence.AttachmentType) async throws -> [String: String] {
        let prompt = "Extract key structured data from this \(type.rawValue) text."
        let schema = """
        {
          "type": "object",
          "additionalProperties": { "type": "string" }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt + "\n\nText:\n" + text, jsonSchema: schema)
        return try JSONDecoder().decode([String: String].self, from: Data(json.utf8))
    }
}
