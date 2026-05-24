import Foundation
import PDFKit
import UIKit

/// A helper utility to decode various attachment types for AI processing.
/// Ensures that text-based files are extracted into the prompt and images are handled separately.
struct FileDecoderHelper {
    /// Decodes a single attachment into a text representation asynchronously.
    static func decode(_ attachment: ChatAttachment) async -> String {
        // Use a background task for heavy decoding operations
        return await Task.detached(priority: .userInitiated) {
            // 1. Handle Images
            if attachment.mimeType.hasPrefix("image") {
                return "[Image Attachment: \(attachment.fileName)]"
            }

            // 2. Handle PDFs
            if attachment.mimeType.contains("pdf") {
                if let document = PDFDocument(data: attachment.data) {
                    var fullText = ""
                    for i in 0..<document.pageCount {
                        if let pageText = document.page(at: i)?.string {
                            fullText += pageText + "\n"
                        }
                    }
                    return fullText.isEmpty ? "[Empty PDF: \(attachment.fileName)]" : fullText
                }
            }

            // 3. Handle RTF
            if attachment.mimeType.contains("rtf") {
                if let attributedString = try? NSAttributedString(data: attachment.data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
                    return attributedString.string
                }
            }

            // 4. Handle Text-based formats (Swift, JSON, TXT, etc.)
            if let text = String(data: attachment.data, encoding: .utf8) {
                return text
            }

            // 5. Fallback for binary data
            return "[Binary Attachment: \(attachment.fileName) (\(attachment.mimeType))]"
        }.value
    }

    /// Decodes a UIImage into a ChatAttachment with compression.
    static func decodeImage(_ image: UIImage, fileName: String = "image.jpg") async -> ChatAttachment {
        return await Task.detached(priority: .userInitiated) {
            let data = image.jpegData(compressionQuality: 0.5) ?? Data()
            return ChatAttachment(data: data, mimeType: "image/jpeg", fileName: fileName)
        }.value
    }

    /// Decodes a UIImage from the Photo Library into a ChatAttachment.
    /// Uses 0.8 compression quality and generates a timestamped filename.
    static func decodeImageFromLibrary(_ image: UIImage) async -> ChatAttachment {
        return await Task.detached(priority: .userInitiated) {
            let data = image.jpegData(compressionQuality: 0.8) ?? Data()
            let fileName = "image_\(Int(Date().timeIntervalSince1970)).jpg"
            return ChatAttachment(data: data, mimeType: "image/jpeg", fileName: fileName)
        }.value
    }

    static func decodeAttachments(_ attachments: [ChatAttachment]) async -> (text: String, images: [ChatAttachment]) {
        return await Task.detached(priority: .userInitiated) {
            var extractedText = ""
            var images: [ChatAttachment] = []

            for attachment in attachments {
                if attachment.mimeType.hasPrefix("image") {
                    images.append(attachment)
                } else if isTextBased(mimeType: attachment.mimeType) {
                    if let text = String(data: attachment.data, encoding: .utf8) {
                        extractedText += "\n\n--- File Content: \(attachment.fileName) ---\n\(text)\n--- End of File ---\n"
                    } else {
                        extractedText += "\n\n[Attachment: \(attachment.fileName) (Unable to decode as UTF-8 text)]\n"
                    }
                } else if attachment.mimeType.contains("pdf"), let document = PDFDocument(data: attachment.data) {
                    var pdfText = ""
                    for i in 0..<document.pageCount {
                        if let pageText = document.page(at: i)?.string {
                            pdfText += pageText + "\n"
                        }
                    }
                    extractedText += "\n\n--- PDF Content: \(attachment.fileName) ---\n\(pdfText)\n--- End of File ---\n"
                } else {
                    extractedText += "\n\n[Attachment: \(attachment.fileName) (Type: \(attachment.mimeType) - Sent as binary reference)]\n"
                }
            }

            return (extractedText, images)
        }.value
    }

    private static func isTextBased(mimeType: String) -> Bool {
        let textTypes = ["text/", "application/json", "application/javascript", "application/xml", "application/x-swift", "rtf"]
        return textTypes.contains { mimeType.contains($0) }
    }
}
