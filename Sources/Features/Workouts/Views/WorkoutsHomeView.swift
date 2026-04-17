import SwiftUI

struct WorkoutsHomeView: View {
    @StateObject private var manager = WorkoutsManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if manager.isOnboardingComplete {
                    workoutsDashboard
                } else {
                    OnboardWorkoutView()
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        WorkoutsSettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
    }

    private var workoutsDashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerSection
                todayPlanSection
                streaksBadgesSection
                nutritionSection
                progressSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(todaySummary)
                .font(.title3.bold())
        }
    }

    private var todayPlanSection: some View {
        NavigationLink {
            WorkoutPlanView()
        } label: {
            sectionCard(
                title: "Today's AI Workout Plan",
                subtitle: manager.todayWorkout?.title ?? "Generate your first AI workout",
                icon: "figure.strengthtraining.traditional"
            )
        }
        .buttonStyle(.plain)
    }

    private var streaksBadgesSection: some View {
        VStack(spacing: 10) {
            NavigationLink {
                StreaksView()
            } label: {
                sectionCard(
                    title: "Streaks",
                    subtitle: "\(manager.streak.currentDays)-day streak · best \(manager.streak.longestDays)",
                    icon: "flame.fill"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                BadgesView()
            } label: {
                sectionCard(
                    title: "Badges",
                    subtitle: "\(manager.badges.filter(\.isUnlocked).count)/\(manager.badges.count) unlocked",
                    icon: "medal.fill"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var nutritionSection: some View {
        NavigationLink {
            NutritionView()
        } label: {
            sectionCard(
                title: "Nutrition Summary",
                subtitle: "\(manager.nutrition.caloriesConsumed)/\(manager.nutrition.calorieGoal) calories",
                icon: "fork.knife"
            )
        }
        .buttonStyle(.plain)
    }

    private var progressSection: some View {
        VStack(spacing: 10) {
            NavigationLink {
                WorkoutProgressDashboardView()
            } label: {
                sectionCard(
                    title: "Progress Overview",
                    subtitle: "Weight, consistency, and calories charts",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                HealthDataView()
            } label: {
                sectionCard(
                    title: "Apple Health Data",
                    subtitle: "Steps, calories, workouts, weight, heart rate",
                    icon: "heart.text.square.fill"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionCard(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var todaySummary: String {
        guard let workout = manager.todayWorkout else {
            return "Let's generate your first workout."
        }

        let done = workout.exercises.filter(\.isCompleted).count
        return "Today's summary: \(done)/\(workout.exercises.count) exercises complete"
    }
}
