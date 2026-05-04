import Foundation

class EmbeddingService {
    static let shared = EmbeddingService()

    private init() {}

    func generateEmbedding(for text: String) async -> [Float] {
        // Mock embedding generation
        return (0..<128).map { _ in Float.random(in: -1...1) }
    }

    func computeSimilarity(v1: [Float], v2: [Float]) -> Float {
        guard v1.count == v2.count else { return 0 }
        let dotProduct = zip(v1, v2).map(*).reduce(0, +)
        let mag1 = sqrt(v1.map { $0 * $0 }.reduce(0, +))
        let mag2 = sqrt(v2.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (mag1 * mag2)
    }
}
