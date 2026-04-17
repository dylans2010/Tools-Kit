import Foundation

private struct AIMentorJSONResponse: Codable {
    let response: String
    let insights: [String]
    let recommendations: [String]
}

final class AIMentorService {
    private let contextBuilder = AIMentorContextBuilder()
    private let ai = AIService.shared
    private let decoder = AIResponseDecoder()

    private let schemaString = """
    {
      "type": "object",
      "required": ["response", "insights", "recommendations"],
      "properties": {
        "response": {"type": "string"},
        "insights": {"type": "array", "items": {"type": "string"}},
        "recommendations": {"type": "array", "items": {"type": "string"}}
      }
    }
    """

    private let schema: AIJSONType = .object([
        "response": .string,
        "insights": .array(.string),
        "recommendations": .array(.string)
    ])

    @MainActor
    func respond(
        to prompt: String,
        imageData: Data?,
        profile: UserFitnessProfile?,
        todayWorkout: WorkoutModel?,
        nutrition: NutritionModel,
        streak: StreakModel,
        badges: [BadgeModel],
        progress: [ProgressModel],
        performances: [WorkoutPerformanceModel],
        healthData: HealthImportedData,
        memory: [MentorMessageModel]
    ) async -> MentorMessageModel {
        let context = contextBuilder.build(
            profile: profile,
            todayWorkout: todayWorkout,
            nutrition: nutrition,
            streak: streak,
            badges: badges,
            progress: progress,
            performances: performances,
            healthData: healthData,
            messages: memory
        )

        let promptString = """
        You are an empathetic fitness mentor. Use the context to reply in STRICT JSON with fields response, insights, and recommendations.

        User question: "\(prompt)"
        Image attached: \(imageData == nil ? "no" : "yes, length \(imageData?.count ?? 0)")

        Context:
        \(context.flattened)
        """

        do {
            let json = try await ai.generateStructuredJSON(
                prompt: promptString,
                jsonSchema: schemaString,
                preferredModel: "openrouter/free"
            )
            let parsed = try decoder.decode(AIMentorJSONResponse.self, from: json, schema: schema)
            return MentorMessageModel(
                role: .assistant,
                text: parsed.response,
                imageHint: imageData == nil ? nil : "Image included",
                insights: parsed.insights,
                recommendations: parsed.recommendations
            )
        } catch {
            return MentorMessageModel(
                role: .assistant,
                text: "I could not decode the AI mentor response. Please try again.",
                imageHint: imageData == nil ? nil : "Image included",
                insights: [],
                recommendations: []
            )
        }
    }
}
