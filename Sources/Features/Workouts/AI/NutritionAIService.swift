import Foundation

struct NutritionAIInput: Sendable {
    let rawText: String
    let sourceType: MealSourceType
    let imageData: Data?
    let voiceTranscript: String?
}

struct MealAnalysisResult: Sendable {
    let record: MealRecord
    let rawJSON: String
}

struct NutritionInsightsModel: Codable, Sendable {
    struct Totals: Codable, Sendable {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fats: Int
    }

    let summary: String
    let totals: Totals
    let insights: [String]
    let recommendations: [String]
}

private struct NutritionAIResponse: Codable, Sendable {
    struct MacroBlock: Codable, Sendable {
        let protein: Double
        let carbs: Double
        let fats: Double
    }

    struct Food: Codable, Identifiable, Sendable {
        let id: UUID
        let name: String
        let portion: String
        let calories: Int

        init(id: UUID = UUID(), name: String, portion: String, calories: Int) {
            self.id = id
            self.name = name
            self.portion = portion
            self.calories = calories
        }
    }

    let mealType: MealType
    let totalCalories: Int
    let macros: MacroBlock
    let foods: [Food]
    let insights: [String]
}

final class NutritionAIService {
    private let ai = AIService.shared
    private let decoder = AIResponseDecoder()
    private let isoFormatter = ISO8601DateFormatter()
    private let schemaString = """
    {
      "type": "object",
      "required": ["mealType", "totalCalories", "macros", "foods", "insights"],
      "properties": {
        "mealType": {"type": "string", "enum": ["breakfast", "lunch", "dinner", "snack"]},
        "totalCalories": {"type": "integer"},
        "macros": {
          "type": "object",
          "required": ["protein", "carbs", "fats"],
          "properties": {
            "protein": {"type": "number"},
            "carbs": {"type": "number"},
            "fats": {"type": "number"}
          }
        },
        "foods": {
          "type": "array",
          "minItems": 1,
          "items": {
            "type": "object",
            "required": ["name", "portion", "calories"],
            "properties": {
              "name": {"type": "string"},
              "portion": {"type": "string"},
              "calories": {"type": "integer"}
            }
          }
        },
        "insights": {
          "type": "array",
          "items": {"type": "string"}
        }
      }
    }
    """

    private let schema: AIJSONType = .object([
        "mealType": .string,
        "totalCalories": .int,
        "macros": .object([
            "protein": .double,
            "carbs": .double,
            "fats": .double
        ]),
        "foods": .array(.object([
            "name": .string,
            "portion": .string,
            "calories": .int
        ])),
        "insights": .array(.string)
    ])

    private let insightsSchemaString = """
    {
      "type": "object",
      "required": ["summary", "totals", "insights", "recommendations"],
      "properties": {
        "summary": {"type": "string"},
        "totals": {
          "type": "object",
          "required": ["calories", "protein", "carbs", "fats"],
          "properties": {
            "calories": {"type": "integer"},
            "protein": {"type": "integer"},
            "carbs": {"type": "integer"},
            "fats": {"type": "integer"}
          }
        },
        "insights": {"type": "array", "items": {"type": "string"}},
        "recommendations": {"type": "array", "items": {"type": "string"}}
      }
    }
    """

    private let insightsSchema: AIJSONType = .object([
        "summary": .string,
        "totals": .object([
            "calories": .int,
            "protein": .int,
            "carbs": .int,
            "fats": .int
        ]),
        "insights": .array(.string),
        "recommendations": .array(.string)
    ])

    func analyzeMeal(
        input: NutritionAIInput,
        profile: UserFitnessProfile?,
        recentMeals: [MealRecord]
    ) async -> Result<MealAnalysisResult, AIResponseDecoderError> {
        let normalizedText = normalize(input.rawText, fallback: input.voiceTranscript)
        let prompt = buildPrompt(
            normalizedText: normalizedText,
            source: input.sourceType,
            imageData: input.imageData,
            profile: profile,
            recentMeals: recentMeals
        )

        var attempt = 0
        var lastError: AIResponseDecoderError?

        while attempt < 3 {
            attempt += 1
            do {
                let json = try await ai.generateStructuredJSON(
                    prompt: promptWithVariation(prompt, attempt: attempt),
                    jsonSchema: schemaString,
                    preferredModel: "openrouter/free"
                )

                let decoded = try decoder.decode(NutritionAIResponse.self, from: json, schema: schema)
                if isDuplicate(response: decoded, recentMeals: recentMeals) {
                    lastError = .decodingFailed("AI returned a duplicate meal suggestion.")
                    continue
                }

                let record = map(response: decoded, input: input, normalizedText: normalizedText)
                return .success(MealAnalysisResult(record: record, rawJSON: json))
            } catch let error as AIResponseDecoderError {
                lastError = error
            } catch {
                lastError = .decodingFailed(error.localizedDescription)
            }
        }

        return .failure(lastError ?? .invalidJSON)
    }

    func recommendedTargets(for profile: UserFitnessProfile) -> (calories: Int, protein: Double, carbs: Double, fats: Double) {
        let age = Double(profile.age ?? 30)
        let bmr = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * age + 5
        var calories = Int(bmr * profile.activityLevel.multiplier)

        switch profile.goal {
        case .gainMuscle, .gainWeight:
            calories += 250
        case .loseWeight:
            calories -= 350
        case .maintain:
            break
        }

        let protein = profile.weightKg * 1.8
        let fats = profile.weightKg * 0.8
        let carbs = max((Double(calories) - ((protein * 4) + (fats * 9))) / 4, 80)

        return (max(calories, 1400), protein, carbs, fats)
    }

    func generateInsights(
        for nutrition: NutritionModel,
        profile: UserFitnessProfile?
    ) async -> Result<NutritionInsightsModel, AIResponseDecoderError> {
        let mealsDescription = nutrition.meals.map {
            "\($0.mealType.rawValue): \($0.name) (\($0.calories) kcal, P\(Int($0.proteinGrams))/C\(Int($0.carbsGrams))/F\(Int($0.fatsGrams)))"
        }.joined(separator: "\n")

        let prompt = """
        Analyze the user's day of eating and return JSON only.

        User profile:
        - goal: \(profile?.goal.rawValue ?? "maintain")
        - weightKg: \(profile?.weightKg ?? 70)
        - activity: \(profile?.activityLevel.rawValue ?? "Moderately active")

        Daily totals:
        - calories goal: \(nutrition.calorieGoal)
        - protein goal: \(Int(nutrition.proteinGoal))
        - carbs goal: \(Int(nutrition.carbsGoal))
        - fats goal: \(Int(nutrition.fatsGoal))

        Meals today:
        \(mealsDescription.isEmpty ? "none" : mealsDescription)

        Provide concise insights and actionable recommendations. Respond with JSON only.
        """

        do {
            let json = try await ai.generateStructuredJSON(
                prompt: prompt,
                jsonSchema: insightsSchemaString,
                preferredModel: "openrouter/free"
            )
            let decoded = try decoder.decode(NutritionInsightsModel.self, from: json, schema: insightsSchema)
            return .success(decoded)
        } catch let error as AIResponseDecoderError {
            return .failure(error)
        } catch {
            return .failure(.decodingFailed(error.localizedDescription))
        }
    }

    private func normalize(_ text: String, fallback: String?) -> String {
        let base = text.isEmpty ? (fallback ?? "") : text
        let lowered = base
            .lowercased()
            .replacingOccurrences(of: "i had", with: "")
            .replacingOccurrences(of: "and", with: ",")
        return lowered
            .components(separatedBy: CharacterSet(charactersIn: ",."))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private func buildPrompt(
        normalizedText: String,
        source: MealSourceType,
        imageData: Data?,
        profile: UserFitnessProfile?,
        recentMeals: [MealRecord]
    ) -> String {
        let timestamp = isoFormatter.string(from: Date())
        let recentSummary = recentMeals.prefix(3).map {
            "- \($0.mealType.rawValue): \($0.name) (\($0.calories) kcal)"
        }.joined(separator: "\n")

        return """
        You are a nutrition logging AI. Respond with STRICT JSON that matches the provided schema. Do not include any text outside JSON.

        Input context:
        - timestamp: \(timestamp)
        - source: \(source.rawValue)
        - normalized input: \(normalizedText)
        - voice transcript (if any): \(source == .voice ? normalizedText : "n/a")
        - image present: \(imageData == nil ? "no" : "yes, base64 length \(imageData?.count ?? 0)")

        User profile:
        - goal: \(profile?.goal.rawValue ?? "maintain")
        - weightKg: \(profile?.weightKg ?? 70)
        - heightCm: \(profile?.heightCm ?? 170)
        - activity: \(profile?.activityLevel.rawValue ?? "Moderately active")

        Recent meals (avoid duplicates, vary foods and preparation): 
        \(recentSummary.isEmpty ? "- none logged" : recentSummary)

        Requirements:
        - Provide realistic calories and macros.
        - Ensure foods vary from the recent meals; do not repeat the same primary item list.
        - Insights must be concise, actionable, and reference the meal composition.
        - Always fill every required field; never return null.
        """
    }

    private func promptWithVariation(_ base: String, attempt: Int) -> String {
        if attempt <= 1 { return base }
        return base + "\nAttempt \(attempt): Previous response was too similar. Force different foods, cooking styles, or sides while staying realistic."
    }

    private func isDuplicate(response: NutritionAIResponse, recentMeals: [MealRecord]) -> Bool {
        guard let latest = recentMeals.first else { return false }
        let incoming = Set(response.foods.map { $0.name.lowercased() })
        let recent = Set(latest.detectedItems.map { $0.name.lowercased() })
        let overlap = Double(incoming.intersection(recent).count)
        let baseline = max(Double(incoming.count), 1)
        return overlap / baseline >= 0.6
    }

    private func map(response: NutritionAIResponse, input: NutritionAIInput, normalizedText: String) -> MealRecord {
        let items: [DetectedFoodItem] = response.foods.map {
            DetectedFoodItem(
                name: $0.name,
                category: .mixed,
                portionDescription: $0.portion,
                estimatedCalories: $0.calories
            )
        }

        return MealRecord(
            mealType: response.mealType,
            name: normalizedText.isEmpty ? response.mealType.rawValue.capitalized : normalizedText.capitalized,
            calories: response.totalCalories,
            proteinGrams: response.macros.protein,
            carbsGrams: response.macros.carbs,
            fatsGrams: response.macros.fats,
            summary: "Logged via \(input.sourceType.rawValue) with AI analysis.",
            insights: response.insights,
            consumedAt: Date(),
            sourceType: input.sourceType,
            rawInput: normalizedText,
            detectedItems: items,
            timestamp: Date(),
            imagePreviewData: input.imageData
        )
    }
}
