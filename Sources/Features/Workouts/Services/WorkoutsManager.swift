import Foundation
import Combine

struct WorkoutsPreferences: Codable, Equatable {
    var preferredDurationMinutes: Int = 45
    var calorieGoal: Int = 2200
    var proteinGoal: Double = 150
    var carbsGoal: Double = 230
    var fatsGoal: Double = 70
    var syncAppleHealth: Bool = true
}

struct WorkoutsSnapshot: Codable {
    var profile: UserFitnessProfile?
    var todayWorkout: WorkoutModel?
    var nutrition: NutritionModel
    var streak: StreakModel
    var badges: [BadgeModel]
    var progress: [ProgressModel]
    var preferences: WorkoutsPreferences
    var healthData: HealthImportedData
}

final class WorkoutsManager: ObservableObject {
    static let shared = WorkoutsManager()

    @Published var profile: UserFitnessProfile?
    @Published var todayWorkout: WorkoutModel?
    @Published var nutrition: NutritionModel
    @Published var streak: StreakModel
    @Published var badges: [BadgeModel]
    @Published var progress: [ProgressModel]
    @Published var preferences: WorkoutsPreferences
    @Published var healthData: HealthImportedData

    private let workoutAIService = WorkoutAIService()
    private let nutritionAIService = NutritionAIService()
    private let healthKitManager = HealthKitManager()
    private let exportService = DataExportService()

    private let calendar = Calendar.current

    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Workouts", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var snapshotURL: URL { saveDir.appendingPathComponent("workouts.json") }

    private init() {
        self.profile = nil
        self.todayWorkout = nil
        self.nutrition = NutritionModel()
        self.streak = StreakModel()
        self.badges = BadgeType.allCases.map { BadgeModel(id: $0) }
        self.progress = []
        self.preferences = WorkoutsPreferences()
        self.healthData = .empty
        load()
        prepareForToday()
    }

    var isOnboardingComplete: Bool {
        profile != nil
    }

    func saveProfile(_ profile: UserFitnessProfile) {
        self.profile = profile

        let targets = nutritionAIService.recommendedTargets(for: profile)
        preferences.calorieGoal = targets.calories
        preferences.proteinGoal = targets.protein
        preferences.carbsGoal = targets.carbs
        preferences.fatsGoal = targets.fats

        nutrition.calorieGoal = targets.calories
        nutrition.proteinGoal = targets.protein
        nutrition.carbsGoal = targets.carbs
        nutrition.fatsGoal = targets.fats

        generateTodayWorkoutIfNeeded(force: true)
        save()
    }

    func generateTodayWorkoutIfNeeded(force: Bool = false) {
        guard let profile else { return }
        if !force,
           let workout = todayWorkout,
           calendar.isDateInToday(workout.date) {
            return
        }

        todayWorkout = workoutAIService.generateDailyPlan(
            profile: profile,
            goal: profile.goal,
            recentProgress: progress,
            streak: streak,
            preferredDurationMinutes: preferences.preferredDurationMinutes
        )
        save()
    }

    func toggleExercise(_ exercise: ExerciseModel) {
        guard var workout = todayWorkout,
              let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }

        workout.exercises[index].isCompleted.toggle()

        if workout.isCompleted && workout.completedAt == nil {
            workout.completedAt = Date()
            streak.registerWorkout(on: Date())
            recordWorkoutCompletion(for: Date())
            evaluateBadges()
        }

        todayWorkout = workout
        save()
    }

    func analyzeMeal(named name: String, imageData: Data?) -> MealAnalysis {
        nutritionAIService.analyzeMeal(name: name, imageData: imageData, profile: profile)
    }

    func addMeal(name: String, analysis: MealAnalysis) {
        rolloverNutritionIfNeeded()

        let meal = MealRecord(
            name: name,
            calories: analysis.calories,
            proteinGrams: analysis.proteinGrams,
            carbsGrams: analysis.carbsGrams,
            fatsGrams: analysis.fatsGrams,
            summary: analysis.summary
        )
        nutrition.meals.insert(meal, at: 0)
        upsertProgress { entry in
            entry.caloriesConsumed = nutrition.caloriesConsumed
        }
        save()
    }

    func updateWeight(_ kg: Double) {
        guard var profile else { return }
        profile.weightKg = kg
        self.profile = profile
        upsertProgress { entry in
            entry.weightKg = kg
        }
        evaluateBadges()
        save()
    }

    func persistPreferences() {
        nutrition.calorieGoal = preferences.calorieGoal
        nutrition.proteinGoal = preferences.proteinGoal
        nutrition.carbsGoal = preferences.carbsGoal
        nutrition.fatsGoal = preferences.fatsGoal
        save()
    }

    func syncHealthData() async {
        guard preferences.syncAppleHealth else { return }
        guard await healthKitManager.requestAuthorization() else { return }

        let data = await healthKitManager.fetchHealthData()
        await MainActor.run {
            self.healthData = data
            self.upsertProgress { entry in
                entry.steps = data.steps
                entry.caloriesBurned = data.caloriesBurned
                if let w = data.latestWeightKg {
                    entry.weightKg = w
                }
            }
            self.save()
        }
    }

    func exportJSON(to url: URL) throws {
        try exportService.exportJSON(snapshot: snapshot(), to: url)
    }

    func exportCSV(to url: URL) throws {
        try exportService.exportCSV(snapshot: snapshot(), to: url)
    }

    func importData(from url: URL) throws {
        let imported = try exportService.importSnapshot(from: url)
        applySnapshot(imported)
    }

    private func prepareForToday() {
        streak.evaluateMissedDay(relativeTo: Date())
        rolloverNutritionIfNeeded()
        generateTodayWorkoutIfNeeded()
        evaluateBadges()
        save()
    }

    private func rolloverNutritionIfNeeded() {
        if !calendar.isDateInToday(nutrition.date) {
            nutrition = NutritionModel(
                date: Date(),
                calorieGoal: preferences.calorieGoal,
                proteinGoal: preferences.proteinGoal,
                carbsGoal: preferences.carbsGoal,
                fatsGoal: preferences.fatsGoal,
                meals: []
            )
        }
    }

    private func recordWorkoutCompletion(for date: Date) {
        upsertProgress(for: date) { entry in
            entry.workoutsCompleted += 1
        }
    }

    private func upsertProgress(for date: Date = Date(), _ update: (inout ProgressModel) -> Void) {
        if let idx = progress.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            update(&progress[idx])
            return
        }

        var new = ProgressModel(date: date)
        update(&new)
        progress.append(new)
        progress.sort { $0.date < $1.date }
    }

    private func evaluateBadges() {
        unlock(.firstWorkout, when: progress.reduce(0) { $0 + $1.workoutsCompleted } >= 1)
        unlock(.sevenDayStreak, when: streak.currentDays >= 7)
        unlock(.thirtyDayStreak, when: streak.currentDays >= 30)

        if let profile,
           let firstWeight = progress.compactMap(\.weightKg).first {
            let currentWeight = profile.weightKg
            switch profile.goal {
            case .loseWeight:
                unlock(.goalAchieved, when: firstWeight - currentWeight >= 2)
            case .gainWeight, .gainMuscle:
                unlock(.goalAchieved, when: currentWeight - firstWeight >= 2)
            case .maintain:
                unlock(.goalAchieved, when: abs(currentWeight - firstWeight) <= 1.5)
            }
        }
    }

    private func unlock(_ badge: BadgeType, when condition: Bool) {
        guard condition,
              let index = badges.firstIndex(where: { $0.id == badge }),
              badges[index].unlockedAt == nil else { return }
        badges[index].unlockedAt = Date()
    }

    private func snapshot() -> WorkoutsSnapshot {
        WorkoutsSnapshot(
            profile: profile,
            todayWorkout: todayWorkout,
            nutrition: nutrition,
            streak: streak,
            badges: badges,
            progress: progress,
            preferences: preferences,
            healthData: healthData
        )
    }

    private func applySnapshot(_ snapshot: WorkoutsSnapshot) {
        self.profile = snapshot.profile
        self.todayWorkout = snapshot.todayWorkout
        self.nutrition = snapshot.nutrition
        self.streak = snapshot.streak
        self.badges = snapshot.badges
        self.progress = snapshot.progress
        self.preferences = snapshot.preferences
        self.healthData = snapshot.healthData
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snapshot()) else { return }
        try? data.write(to: snapshotURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: snapshotURL),
              let decoded = try? JSONDecoder().decode(WorkoutsSnapshot.self, from: data) else { return }
        applySnapshot(decoded)
    }
}
