import Foundation
import Combine

final class HabitsManager: ObservableObject {
    static let shared = HabitsManager()

    @Published var habits: [Habit] = []
    private let aiService = AIService.shared
    private let aiDecoder = AIResponseDecoder()

    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Habits", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var habitsURL: URL {
        saveDir.appendingPathComponent("habits.json")
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private init() { load() }

    // MARK: - CRUD

    func addHabit(_ habit: Habit) {
        habits.insert(habit, at: 0)
        save()
    }

    func updateHabit(_ habit: Habit) {
        if let idx = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[idx] = habit
            save()
        }
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        save()
    }

    // MARK: - Logging

    func increment(habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let key = todayKey()
        habits[idx].completionHistory[key, default: 0] += 1
        save()
    }

    func decrement(habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let key = todayKey()
        let current = habits[idx].completionHistory[key, default: 0]
        if current > 0 {
            habits[idx].completionHistory[key] = current - 1
            save()
        }
    }

    func resetToday(habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx].completionHistory[todayKey()] = 0
        save()
    }

    // MARK: - Queries

    func todayCount(for habit: Habit) -> Int {
        habit.completionHistory[todayKey()] ?? 0
    }

    func completionRate(for habit: Habit, days: Int = 30) -> Double {
        let calendar = Calendar.current
        var completed = 0
        for offset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -offset, to: Date()) {
                let key = dateFormatter.string(from: date)
                if (habit.completionHistory[key] ?? 0) >= habit.targetCount { completed += 1 }
            }
        }
        return Double(completed) / Double(days)
    }

    // MARK: - Persistence

    private func todayKey() -> String {
        dateFormatter.string(from: Date())
    }

    private func load() {
        guard let data = try? Data(contentsOf: habitsURL),
              let decoded = try? JSONDecoder().decode([Habit].self, from: data) else { return }
        habits = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(habits) else { return }
        try? data.write(to: habitsURL, options: .atomic)
    }

    // MARK: - AI Habit Coaching

    struct AIHabitInsights: Codable {
        let suggestedHabits: [String]
        let behaviorPatterns: [String]
        let optimizationTips: [String]
        let successLikelihood: [String]
    }

    private var aiSchemaString: String {
        """
        {
          "type": "object",
          "required": ["suggestedHabits", "behaviorPatterns", "optimizationTips", "successLikelihood"],
          "properties": {
            "suggestedHabits": { "type": "array", "items": { "type": "string" } },
            "behaviorPatterns": { "type": "array", "items": { "type": "string" } },
            "optimizationTips": { "type": "array", "items": { "type": "string" } },
            "successLikelihood": { "type": "array", "items": { "type": "string" } }
          }
        }
        """
    }

    private var aiSchema: AIJSONType {
        .object([
            "suggestedHabits": .array(.string),
            "behaviorPatterns": .array(.string),
            "optimizationTips": .array(.string),
            "successLikelihood": .array(.string)
        ])
    }

    @MainActor
    func generateHabitInsights(goalPrompt: String) async throws -> AIHabitInsights {
        // Drive habit recommendations from strict JSON to keep UI deterministic.
        let progressContext = habits.map { habit in
            "\(habit.name): streak \(habit.currentStreak), weekly rate \(Int(habit.weeklyCompletionRate() * 100))%"
        }.joined(separator: "\n")
        let prompt = """
        User goals:
        \(goalPrompt)

        Current habit performance:
        \(progressContext)
        """
        let json = try await aiService.generateStructuredJSON(
            prompt: prompt,
            jsonSchema: aiSchemaString,
            preferredModel: "openrouter/free",
            systemPrompt: "You are a habit coach. Return strict JSON only."
        )
        return try aiDecoder.decode(AIHabitInsights.self, from: json, schema: aiSchema)
    }
}
