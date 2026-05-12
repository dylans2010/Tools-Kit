import Foundation
import Combine
import SwiftUI

enum FileFormat: String, CaseIterable, Identifiable, Sendable {
    case pdf = "PDF"
    case docx = "DOCX"
    case txt = "TXT"
    case md = "Markdown"
    case html = "HTML"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .docx: return "doc.text"
        case .txt: return "doc.plaintext"
        case .md: return "doc.text.fill"
        case .html: return "doc.text.below.ecg"
        }
    }
}

class FileConverterBackend: ObservableObject {
    @Published var selectedFileURL: URL?
    @Published var targetFormat: FileFormat = .pdf
    @Published var conversionProgress: Double = 0.0
    @Published var isConverting = false
    @Published var convertedFileURL: URL?
    @Published var error: String? = nil

    func convert() {
        guard let source = selectedFileURL else { return }

        isConverting = true
        conversionProgress = 0.0
        error = nil
        convertedFileURL = nil

        // Simulate real file conversion process with incremental progress
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            self.conversionProgress += 0.1

            if self.conversionProgress >= 1.0 {
                timer.invalidate()

                // Create a "converted" dummy file in temp directory
                let fileName = source.deletingPathExtension().lastPathComponent + "." + self.targetFormat.rawValue.lowercased()
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                do {
                    // In a real app, you'd use a conversion library here
                    // We'll write the source filename to the new file to simulate content
                    let content = "Simulated \(self.targetFormat.rawValue) content from \(source.lastPathComponent)"
                    try content.write(to: tempURL, atomically: true, encoding: .utf8)

                    DispatchQueue.main.async {
                        self.convertedFileURL = tempURL
                        self.isConverting = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.error = "Failed to write converted file."
                        self.isConverting = false
                    }
                }
            }
        }
    }

    func reset() {
        selectedFileURL = nil
        convertedFileURL = nil
        conversionProgress = 0.0
        error = nil
    }
}
