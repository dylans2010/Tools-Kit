import Foundation

struct HFRecommendation: Codable, Identifiable {
    var id: String { model_link }
    let model_title: String
    let model_description: String
    let model_link: String
    let model_why_recommendation: String
}

class HuggingFaceRecommendationService {
    static let shared = HuggingFaceRecommendationService()

    func getRecommendations() async throws -> [HFRecommendation] {
        let profile = DeviceProfile.current()
        guard let profileJSON = profile.toJSONString() else {
            throw AIError.decodingFailed
        }

        let prompt = """
        Based on my iOS device profile:
        \(profileJSON)

        Recommend 5 GGUF models from HuggingFace that would run optimally on this device.
        Consider RAM and storage constraints.

        Return EXACTLY 5 objects in this JSON format:
        [
          {
            "model_title": "String",
            "model_description": "String",
            "model_link": "String (HuggingFace ID like 'bartowski/Llama-3-8B-Instruct-GGUF')",
            "model_why_recommendation": "String"
          }
        ]

        No extra text, strict JSON only.
        """

        let schema = """
        [
          {
            "model_title": "string",
            "model_description": "string",
            "model_link": "string",
            "model_why_recommendation": "string"
          }
        ]
        """

        let response = try await AIService.shared.generateStructuredJSON(
            prompt: prompt,
            jsonSchema: schema
        )

        let decoder = JSONDecoder()
        do {
            let recommendations = try decoder.decode([HFRecommendation].self, from: Data(response.utf8))
            return Array(recommendations.prefix(5))
        } catch {
            SDKLogStore.shared.log("HF Recommendation decoding error: \(error). Response: \(response)", source: "HFRecommendationService", level: .error)
            throw AIError.decodingFailed
        }
    }
}
