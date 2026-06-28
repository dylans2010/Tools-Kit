import Foundation
import SwiftUI

@available(iOS 27.0, *)
@MainActor
class SCKExportManager {
    static let shared = SCKExportManager()

    func exportToMarkdown(session: SCKRecordingSession) -> String {
        var md = "# \(session.title)\n\n"
        md += "## Summary\n\(session.summary ?? "N/A")\n\n"
        md += "## Action Items\n"
        if let items = session.actionItems {
            for item in items {
                md += "- [ ] \(item)\n"
            }
        } else {
            md += "N/A\n"
        }
        md += "\n## Transcript\n"
        for segment in session.transcript {
            md += "**[\(formatTimestamp(segment.timestamp))]** \(segment.speaker ?? "Unknown"): \(segment.text)\n"
        }
        return md
    }

    private func formatTimestamp(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    func exportToJSON(session: SCKRecordingSession) -> Data? {
        return try? JSONEncoder().encode(session)
    }

    func generatePDF(session: SCKRecordingSession) -> URL? {
        // Implementation using UIGraphicsPDFRenderer
        return nil
    }
}
