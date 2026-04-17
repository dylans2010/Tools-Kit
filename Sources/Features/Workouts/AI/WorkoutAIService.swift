import Foundation

final class WorkoutAIService {
    func generateDailyPlan(
        profile: UserFitnessProfile,
        goal: UserFitnessProfile.FitnessGoal,
        recentProgress: [ProgressModel],
        streak: StreakModel,
        preferredDurationMinutes: Int
    ) -> WorkoutModel {
        let intensity = adjustedIntensity(recentProgress: recentProgress, streak: streak)
        let exercises = exerciseTemplate(goal: goal, intensity: intensity)
        let estimatedDuration = max(preferredDurationMinutes, exercises.reduce(0) { $0 + $1.durationMinutes })

        return WorkoutModel(
            date: Date(),
            title: "AI Daily \(goal.rawValue)",
            estimatedDurationMinutes: estimatedDuration,
            exercises: exercises,
            notes: "Adapted for \(profile.activityLevel.rawValue.lowercased()) activity with \(intensity.rawValue) intensity."
        )
    }

    private func adjustedIntensity(recentProgress: [ProgressModel], streak: StreakModel) -> Intensity {
        let calendar = Calendar.current
        let now = Date()
        let weeklyWorkouts = recentProgress
            .filter {
                let days = calendar.dateComponents([.day], from: $0.date, to: now).day ?? 99
                return days >= 0 && days <= 7
            }
            .reduce(0) { $0 + $1.workoutsCompleted }

        if streak.currentDays >= 14 && weeklyWorkouts >= 5 { return .high }
        if streak.currentDays >= 4 || weeklyWorkouts >= 3 { return .medium }
        return .low
    }

    private func exerciseTemplate(goal: UserFitnessProfile.FitnessGoal, intensity: Intensity) -> [ExerciseModel] {
        let baseSets: Int
        let baseReps: Int
        let rest: Int

        switch intensity {
        case .low:
            baseSets = 3; baseReps = 10; rest = 90
        case .medium:
            baseSets = 4; baseReps = 10; rest = 75
        case .high:
            baseSets = 5; baseReps = 8; rest = 60
        }

        switch goal {
        case .gainMuscle:
            return [
                ExerciseModel(name: "Squats", sets: baseSets, reps: baseReps, durationMinutes: 12, restSeconds: rest),
                ExerciseModel(name: "Bench Press", sets: baseSets, reps: baseReps, durationMinutes: 10, restSeconds: rest),
                ExerciseModel(name: "Rows", sets: baseSets, reps: baseReps, durationMinutes: 10, restSeconds: rest),
                ExerciseModel(name: "Core Plank", sets: 3, reps: 1, durationMinutes: 8, restSeconds: 45)
            ]
        case .loseWeight:
            return [
                ExerciseModel(name: "HIIT Circuit", sets: 4, reps: 1, durationMinutes: 15, restSeconds: 45),
                ExerciseModel(name: "Bodyweight Lunges", sets: baseSets, reps: 12, durationMinutes: 10, restSeconds: rest),
                ExerciseModel(name: "Push-ups", sets: baseSets, reps: baseReps, durationMinutes: 8, restSeconds: rest),
                ExerciseModel(name: "Fast Walk", sets: 1, reps: 1, durationMinutes: 20, restSeconds: 0)
            ]
        case .maintain:
            return [
                ExerciseModel(name: "Full Body Circuit", sets: 3, reps: 12, durationMinutes: 18, restSeconds: 60),
                ExerciseModel(name: "Mobility Routine", sets: 1, reps: 1, durationMinutes: 10, restSeconds: 0),
                ExerciseModel(name: "Light Cardio", sets: 1, reps: 1, durationMinutes: 20, restSeconds: 0)
            ]
        case .gainWeight:
            return [
                ExerciseModel(name: "Deadlift", sets: baseSets, reps: max(baseReps - 2, 6), durationMinutes: 12, restSeconds: rest),
                ExerciseModel(name: "Overhead Press", sets: baseSets, reps: baseReps, durationMinutes: 10, restSeconds: rest),
                ExerciseModel(name: "Pull-ups", sets: baseSets, reps: 8, durationMinutes: 10, restSeconds: rest),
                ExerciseModel(name: "Farmer Carry", sets: 3, reps: 1, durationMinutes: 8, restSeconds: 60)
            ]
        }
    }
}

private enum Intensity: String {
    case low
    case medium
    case high
}
