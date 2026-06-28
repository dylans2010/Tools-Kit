#if canImport(ScreenCaptureKit)

import Foundation


@available(iOS 27.0, *)
@MainActor
class SCKSummaryManager {
    static let shared = SCKSummaryManager()

    func generateSummary(for session: SCKRecordingSession) async throws -> String {
        let transcriptText = session.transcript.map { $0.text }.joined(separator: " ")
        let ocrText = session.ocrResults.map { $0.text }.joined(separator: "\n")

        let prompt = """
        Generate a comprehensive summary for a recording session.
        Type: \(session.featureType.rawValue)
        Transcript: \(transcriptText)
        OCR Content: \(ocrText)

        Provide:
        1. A concise TL;DR.
        2. Detailed key points.
        3. Overall conclusion.
        Use Markdown formatting.
        """

        return try await AIService.shared.processText(prompt: prompt, systemPrompt: "You are an expert content analyzer.")
    }

    func extractActionItems(for session: SCKRecordingSession) async throws -> [String] {
        let transcriptText = session.transcript.map { $0.text }.joined(separator: " ")

        let prompt = """
        Extract action items from the following transcript:
        \(transcriptText)

        Return a JSON array of strings, each being a clear action item.
        Return ONLY the JSON array.
        """

        let jsonString = try await AIService.shared.processText(prompt: prompt, systemPrompt: "You are a professional secretary.")
        let data = Data(jsonString.utf8)
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
}


#endif
