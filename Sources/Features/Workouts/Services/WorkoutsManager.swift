import Foundation
import Combine

struct WorkoutsPreferences: Codable, Equatable, Sendable {
    var preferredDurationMinutes: Int = 45
    var calorieGoal: Int = 2200
    var proteinGoal: Double = 150
    var carbsGoal: Double = 230
    var fatsGoal: Double = 70
    var syncAppleHealth: Bool = true
}

struct WorkoutsSnapshot: Codable, Sendable {
    var profile: UserFitnessProfile?
    var todayWorkout: WorkoutModel?
    var nutrition: NutritionModel
    var streak: StreakModel
    var badges: [BadgeModel]
    var progress: [ProgressModel]
    var preferences: WorkoutsPreferences
    var healthData: HealthImportedData
    var mentorMessages: [MentorMessageModel]
    var workoutSessions: [WorkoutSessionModel]
    var performance: [WorkoutPerformanceModel]
    var mealPlans: [MealPlanModel]
    var recentGeneratedWorkouts: [WorkoutModel]

    private enum CodingKeys: String, CodingKey, Sendable {
        case profile, todayWorkout, nutrition, streak, badges, progress, preferences, healthData, mentorMessages, workoutSessions, performance, mealPlans, recentGeneratedWorkouts
    }

    init(
        profile: UserFitnessProfile?,
        todayWorkout: WorkoutModel?,
        nutrition: NutritionModel,
        streak: StreakModel,
        badges: [BadgeModel],
        progress: [ProgressModel],
        preferences: WorkoutsPreferences,
        healthData: HealthImportedData,
        mentorMessages: [MentorMessageModel],
        workoutSessions: [WorkoutSessionModel],
        performance: [WorkoutPerformanceModel],
        mealPlans: [MealPlanModel],
        recentGeneratedWorkouts: [WorkoutModel]
    ) {
        self.profile = profile
        self.todayWorkout = todayWorkout
        self.nutrition = nutrition
        self.streak = streak
        self.badges = badges
        self.progress = progress
        self.preferences = preferences
        self.healthData = healthData
        self.mentorMessages = mentorMessages
        self.workoutSessions = workoutSessions
        self.performance = performance
        self.mealPlans = mealPlans
        self.recentGeneratedWorkouts = recentGeneratedWorkouts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decodeIfPresent(UserFitnessProfile.self, forKey: .profile)
        todayWorkout = try container.decodeIfPresent(WorkoutModel.self, forKey: .todayWorkout)
        nutrition = try container.decodeIfPresent(NutritionModel.self, forKey: .nutrition) ?? NutritionModel()
        streak = try container.decodeIfPresent(StreakModel.self, forKey: .streak) ?? StreakModel()
        badges = try container.decodeIfPresent([BadgeModel].self, forKey: .badges) ?? BadgeType.allCases.map { BadgeModel(id: $0) }
        progress = try container.decodeIfPresent([ProgressModel].self, forKey: .progress) ?? []
        preferences = try container.decodeIfPresent(WorkoutsPreferences.self, forKey: .preferences) ?? WorkoutsPreferences()
        healthData = try container.decodeIfPresent(HealthImportedData.self, forKey: .healthData) ?? .empty
        mentorMessages = try container.decodeIfPresent([MentorMessageModel].self, forKey: .mentorMessages) ?? []
        workoutSessions = try container.decodeIfPresent([WorkoutSessionModel].self, forKey: .workoutSessions) ?? []
        performance = try container.decodeIfPresent([WorkoutPerformanceModel].self, forKey: .performance) ?? []
        mealPlans = try container.decodeIfPresent([MealPlanModel].self, forKey: .mealPlans) ?? []
        recentGeneratedWorkouts = try container.decodeIfPresent([WorkoutModel].self, forKey: .recentGeneratedWorkouts) ?? []
    }
}

final class WorkoutsManager: ObservableObject {
    nonisolated(unsafe) static let shared = WorkoutsManager()

    @Published var profile: UserFitnessProfile?
    @Published var todayWorkout: WorkoutModel?
    @Published var nutrition: NutritionModel
    @Published var streak: StreakModel
    @Published var badges: [BadgeModel]
    @Published var progress: [ProgressModel]
    @Published var preferences: WorkoutsPreferences
    @Published var healthData: HealthImportedData
    @Published var mentorMessages: [MentorMessageModel]
    @Published var workoutSessions: [WorkoutSessionModel]
    @Published var performance: [WorkoutPerformanceModel]
    @Published var mealPlans: [MealPlanModel]
    @Published var liveHeartRate: Double
    @Published var recentGeneratedWorkouts: [WorkoutModel]

    private let workoutAIService = WorkoutAIService()
    private let nutritionAIService = NutritionAIService()
    private let healthKitManager = HealthKitManager()
    private let exportService = DataExportService()
    private let mentorService = AIMentorService()
    private let mentorMemoryStore = AIMentorMemoryStore()
    private let coachService = WorkoutCoachService()
    private let mealPlanningService = MealPlanningService()
    private let volumeNormalizationFactor: Double = 120.0

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
        self.mentorMessages = []
        self.workoutSessions = []
        self.performance = []
        self.mealPlans = []
        self.liveHeartRate = 0
        self.recentGeneratedWorkouts = []
        load()
        prepareForToday()
    }

    var isOnboardingComplete: Bool {
        profile != nil
    }

    var currentMealPlan: MealPlanModel? {
        mealPlans.first(where: { calendar.isDateInToday($0.date) })
    }

    var mentorContextPreview: String {
        AIMentorContextBuilder()
            .build(
                profile: profile,
                todayWorkout: todayWorkout,
                nutrition: nutrition,
                streak: streak,
                badges: badges,
                progress: progress,
                performances: performance,
                healthData: healthData,
                messages: mentorMessages
            )
            .flattened
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
        generateMealPlanIfNeeded(force: true)
        save()
    }

    func generateTodayWorkoutIfNeeded(force: Bool = false) {
        Task { @MainActor in
            _ = await generateAIWorkout(force: force)
        }
    }

    func toggleExercise(_ exercise: ExerciseModel) {
        guard var workout = todayWorkout,
              let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }

        workout.exercises[index].isCompleted.toggle()

        if workout.isCompleted && workout.completedAt == nil {
            workout.completedAt = Date()
            streak.registerWorkout(on: Date())
            streak.markCompletion(for: Date(), completed: true)
            recordWorkoutCompletion(for: Date())
            evaluateBadges()
            mergeWithHabitSystemIfPossible()
        }

        todayWorkout = workout
        save()
    }

    @MainActor
    func generateAIWorkout(force: Bool = false) async -> Result<WorkoutModel, AIResponseDecoderError> {
        guard let profile else { return .failure(.decodingFailed("Missing profile")) }
        if !force,
           let workout = todayWorkout,
           calendar.isDateInToday(workout.date) {
            return .success(workout)
        }

        let guidance = coachService.buildGuidance(
            streak: streak,
            recentPerformance: Array(performance.suffix(14)),
            recentSessions: Array(workoutSessions.suffix(14))
        )

        let result = await workoutAIService.generateWorkout(
            profile: profile,
            progress: progress,
            streak: streak,
            nutrition: nutrition,
            recentWorkouts: recentGeneratedWorkouts,
            performances: performance,
            guidance: guidance,
            preferredDuration: preferences.preferredDurationMinutes
        )

        switch result {
        case .success(var workout):
            workout.notes += " \(guidance.note) Recovery score: \(guidance.recovery.score)."
            todayWorkout = workout
            recentGeneratedWorkouts.insert(workout, at: 0)
            recentGeneratedWorkouts = Array(recentGeneratedWorkouts.prefix(3))
            save()
            return .success(workout)
        case .failure(let error):
            return .failure(error)
        }
    }

    @MainActor
    func logMeal(using input: NutritionAIInput) async -> Result<MealRecord, AIResponseDecoderError> {
        rolloverNutritionIfNeeded()

        let result = await nutritionAIService.analyzeMeal(
            input: input,
            profile: profile,
            recentMeals: nutrition.meals
        )

        switch result {
        case .success(let analysis):
            nutrition.meals.insert(analysis.record, at: 0)
            upsertProgress { entry in
                entry.caloriesConsumed = nutrition.caloriesConsumed
                entry.proteinConsumed = nutrition.proteinConsumed
                entry.carbsConsumed = nutrition.carbsConsumed
                entry.fatsConsumed = nutrition.fatsConsumed
            }
            save()
            return .success(analysis.record)
        case .failure(let error):
            return .failure(error)
        }
    }

    @MainActor
    func generateNutritionInsights() async -> Result<NutritionInsightsModel, AIResponseDecoderError> {
        await nutritionAIService.generateInsights(for: nutrition, profile: profile)
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

    func refreshLiveHeartRate() async {
        liveHeartRate = await healthKitManager.fetchLatestHeartRate() ?? healthData.averageHeartRate ?? 0
    }

    func updateWorkoutReminder(_ enabled: Bool) {
        streak.workoutReminderEnabled = enabled
        save()
    }

    func saveWorkoutSession(title: String, fatigueLevel: Int, logs: [ExerciseSessionLog], notes: String) {
        let session = WorkoutSessionModel(
            workoutTitle: title,
            startedAt: Date(),
            endedAt: Date(),
            fatigueLevel: fatigueLevel,
            exerciseLogs: logs,
            notes: notes
        )
        workoutSessions.insert(session, at: 0)

        let strengthScore = min(max(session.totalVolume / volumeNormalizationFactor, 0), 100)
        let consistencyScore = min(Double(streak.currentDays) * 5, 100)
        let missed = estimatedMissedSessionsLast14Days()

        let perf = WorkoutPerformanceModel(
            date: Date(),
            strengthScore: strengthScore,
            consistencyScore: consistencyScore,
            fatigueLevel: fatigueLevel,
            missedSessions: missed,
            recoveryScore: max(100 - fatigueLevel * 15 - missed * 5, 10)
        )
        performance.insert(perf, at: 0)

        save()
    }

    func generateMealPlanIfNeeded(force: Bool = false) {
        if !force, currentMealPlan != nil {
            return
        }
        let plan = mealPlanningService.generatePlan(for: Date(), nutrition: nutrition, profile: profile)
        mealPlans.removeAll { calendar.isDateInToday($0.date) }
        mealPlans.insert(plan, at: 0)
        save()
    }

    func generateWeeklyMealPlans() {
        let plans = mealPlanningService.generateWeeklyPlan(startingAt: Date(), nutrition: nutrition, profile: profile)
        mealPlans.removeAll { plan in plans.contains(where: { calendar.isDate($0.date, inSameDayAs: plan.date) }) }
        mealPlans.insert(contentsOf: plans, at: 0)
        save()
    }

    func ensureMentorMemoryLoaded() {
        if mentorMessages.isEmpty {
            mentorMessages = mentorMemoryStore.load()
        }
        if mentorMessages.isEmpty {
            mentorMessages = [MentorMessageModel(role: .assistant, text: "I’m your AI mentor. Ask about workouts, meals, fatigue, or progress.")]
        }
    }

    @MainActor
    func sendMentorMessage(_ text: String, imageData: Data?) async {
        ensureMentorMemoryLoaded()

        let userMessage = MentorMessageModel(role: .user, text: text, imageHint: imageData == nil ? nil : "Image attached")
        mentorMessages.append(userMessage)

        let response = await mentorService.respond(
                to: text,
                imageData: imageData,
                profile: profile,
                todayWorkout: todayWorkout,
                nutrition: nutrition,
                streak: streak,
                badges: badges,
                progress: progress,
                performances: performance,
                healthData: healthData,
                memory: mentorMessages
            )
        mentorMessages.append(response)
        mentorMemoryStore.save(mentorMessages)
        save()
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
        generateMealPlanIfNeeded()
        evaluateBadges()
        ensureMentorMemoryLoaded()
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
        let targetDay = calendar.startOfDay(for: date)

        var low = 0
        var high = progress.count
        while low < high {
            let mid = (low + high) / 2
            let midDay = calendar.startOfDay(for: progress[mid].date)
            if midDay < targetDay {
                low = mid + 1
            } else {
                high = mid
            }
        }

        if low < progress.count, calendar.isDate(progress[low].date, inSameDayAs: date) {
            update(&progress[low])
            return
        }

        var new = ProgressModel(date: date)
        update(&new)
        progress.insert(new, at: low)
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

        let proteinHits = progress.prefix(5).filter { $0.proteinConsumed >= nutrition.proteinGoal }.count
        unlock(.proteinPro, when: proteinHits >= 5)
    }

    private func unlock(_ badge: BadgeType, when condition: Bool) {
        guard condition,
              let index = badges.firstIndex(where: { $0.id == badge }),
              badges[index].unlockedAt == nil else { return }
        badges[index].unlockedAt = Date()
    }

    private func estimatedMissedSessionsLast14Days() -> Int {
        let workouts = progress.suffix(14).reduce(0) { $0 + $1.workoutsCompleted }
        return max(14 / 2 - workouts, 0)
    }

    private func mergeWithHabitSystemIfPossible() {
        guard let workoutHabit = HabitsManager.shared.habits.first(where: { $0.name.lowercased().contains("workout") }) else { return }
        HabitsManager.shared.increment(habit: workoutHabit)
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
            healthData: healthData,
            mentorMessages: mentorMessages,
            workoutSessions: workoutSessions,
            performance: performance,
            mealPlans: mealPlans,
            recentGeneratedWorkouts: recentGeneratedWorkouts
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
        self.mentorMessages = snapshot.mentorMessages
        self.workoutSessions = snapshot.workoutSessions
        self.performance = snapshot.performance
        self.mealPlans = snapshot.mealPlans
        self.recentGeneratedWorkouts = snapshot.recentGeneratedWorkouts
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
