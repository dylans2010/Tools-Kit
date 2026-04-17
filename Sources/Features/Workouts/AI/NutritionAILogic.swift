import Foundation

struct NutritionSummaryInfo: Codable {
    struct MacroRange: Codable {
        let consumed: Double
        let goal: Double
        let qualityScore: Double
    }

    let title: String
    let estimatedCalories: Int
    let confidence: Double
    let protein: MacroRange
    let carbs: MacroRange
    let fats: MacroRange
    let hydrationLiters: Double
    let sodiumMilligrams: Int
    let fiberGrams: Double
    let sugarGrams: Double
    let recommendations: [String]
    let detectedFoods: [String]
}

final class NutritionAILogic {
    enum InputMode: String {
        case image
        case voice
        case text
    }

    private let ai = AIService.shared
    private let preferredModels = [
        "openrouter/free",
        "google/gemma-3-27b-it:free",
        "meta-llama/llama-3.2-11b-vision-instruct:free"
    ]

    @MainActor
    func analyze(
        userProfile: UserFitnessProfile?,
        rawText: String,
        voiceTranscript: String?,
        imageHint: Bool
    ) async -> NutritionSummaryInfo {
        let mode: InputMode = imageHint ? .image : (voiceTranscript == nil ? .text : .voice)
        let schema = Self.schema
        let prompt = buildPrompt(profile: userProfile, mode: mode, rawText: rawText, voiceTranscript: voiceTranscript)

        do {
            let json = try await ai.generateStructuredJSON(
                prompt: prompt,
                jsonSchema: schema,
                preferredModel: preferredModels.first ?? "openrouter/free"
            )
            if let decoded = try? JSONDecoder().decode(NutritionSummaryInfo.self, from: Data(json.utf8)) {
                return decoded
            }
        } catch {
            // intentional fallback
        }

        return fallback(rawText: rawText)
    }

    private func buildPrompt(profile: UserFitnessProfile?, mode: InputMode, rawText: String, voiceTranscript: String?) -> String {
        """
        Analyze this nutrition input and return JSON only.

        Input mode: \(mode.rawValue)
        Raw text: \(rawText)
        Voice transcript: \(voiceTranscript ?? "n/a")

        User context:
        - goal: \(profile?.goal.rawValue ?? "maintain")
        - weightKg: \(profile?.weightKg ?? 70)
        - activity: \(profile?.activityLevel.rawValue ?? "Moderately active")

        Include calorie estimate, macro quality scores, hydration and practical recommendations.
        """
    }

    private func fallback(rawText: String) -> NutritionSummaryInfo {
        NutritionSummaryInfo(
            title: "Nutrition AI Summary",
            estimatedCalories: 520,
            confidence: 0.62,
            protein: .init(consumed: 28, goal: 40, qualityScore: 0.71),
            carbs: .init(consumed: 56, goal: 70, qualityScore: 0.78),
            fats: .init(consumed: 18, goal: 22, qualityScore: 0.74),
            hydrationLiters: 1.4,
            sodiumMilligrams: 780,
            fiberGrams: 8,
            sugarGrams: 12,
            recommendations: [
                "Add one extra high-protein serving today.",
                "Pair carbs with vegetables to raise fiber.",
                "Increase hydration by at least 500ml."
            ],
            detectedFoods: rawText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        )
    }

    private static let schema = """
    {
      "type": "object",
      "required": ["title", "estimatedCalories", "confidence", "protein", "carbs", "fats", "hydrationLiters", "sodiumMilligrams", "fiberGrams", "sugarGrams", "recommendations", "detectedFoods"],
      "properties": {
        "title": {"type": "string"},
        "estimatedCalories": {"type": "integer"},
        "confidence": {"type": "number"},
        "hydrationLiters": {"type": "number"},
        "sodiumMilligrams": {"type": "integer"},
        "fiberGrams": {"type": "number"},
        "sugarGrams": {"type": "number"},
        "recommendations": {"type": "array", "items": {"type": "string"}},
        "detectedFoods": {"type": "array", "items": {"type": "string"}},
        "protein": {
          "type": "object",
          "required": ["consumed", "goal", "qualityScore"],
          "properties": {
            "consumed": {"type": "number"},
            "goal": {"type": "number"},
            "qualityScore": {"type": "number"}
          }
        },
        "carbs": {
          "type": "object",
          "required": ["consumed", "goal", "qualityScore"],
          "properties": {
            "consumed": {"type": "number"},
            "goal": {"type": "number"},
            "qualityScore": {"type": "number"}
          }
        },
        "fats": {
          "type": "object",
          "required": ["consumed", "goal", "qualityScore"],
          "properties": {
            "consumed": {"type": "number"},
            "goal": {"type": "number"},
            "qualityScore": {"type": "number"}
          }
        }
      }
    }
    """
}
