import Foundation

/// Handles generation and management of vector embeddings for semantic search.
final class EmbeddingService {
    nonisolated(unsafe) static let shared = EmbeddingService()

    private init() {}

    /// Generates a vector embedding for the given text.
    func generateEmbedding(for text: String) async throws -> [Float] {
        // Production implementation would call an embedding model
        print("[EmbeddingService] Generating embedding for text length: \(text.count)")

        // Simulating processing time
        try await Task.sleep(nanoseconds: 100 * 1000 * 1000)

        // Return a stable representation for local searching logic
        return Array(repeating: 0.1, count: 1536)
    }

    /// Calculates cosine similarity between two embeddings.
    func calculateSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }

        var dotProduct: Float = 0
        var magnitudeA: Float = 0
        var magnitudeB: Float = 0

        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            magnitudeA += a[i] * a[i]
            magnitudeB += b[i] * b[i]
        }

        magnitudeA = sqrt(magnitudeA)
        magnitudeB = sqrt(magnitudeB)

        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }
        return dotProduct / (magnitudeA * magnitudeB)
    }
}
