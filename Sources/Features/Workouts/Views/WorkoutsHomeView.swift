import SwiftUI

struct WorkoutsHomeView: View {
    enum Tab: String, CaseIterable, Identifiable, Sendable {
        case dashboard
        case plan
        case nutrition
        case health

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dashboard: return "Home"
            case .plan: return "Plan"
            case .nutrition: return "Nutrition"
            case .health: return "Health"
            }
        }

        var symbol: String {
            switch self {
            case .dashboard: return "house.fill"
            case .plan: return "figure.strengthtraining.functional"
            case .nutrition: return "fork.knife.circle.fill"
            case .health: return "heart.text.square.fill"
            }
        }
    }

    @StateObject private var manager = WorkoutsManager.shared
    @State private var selectedTab: Tab = .dashboard
    @State private var showScanSheet = false
    @State private var showVoiceSheet = false

    var body: some View {
        Group {
            if manager.isOnboardingComplete {
                TabView(selection: $selectedTab) {
                    NavigationStack { dashboardRoot }
                        .tag(Tab.dashboard)
                        .tabItem { Label(Tab.dashboard.title, systemImage: Tab.dashboard.symbol) }

                    NavigationStack { WorkoutPlanView() }
                        .tag(Tab.plan)
                        .tabItem { Label(Tab.plan.title, systemImage: Tab.plan.symbol) }

                    NavigationStack { NutritionView() }
                        .tag(Tab.nutrition)
                        .tabItem { Label(Tab.nutrition.title, systemImage: Tab.nutrition.symbol) }

                    NavigationStack { HealthDataView() }
                        .tag(Tab.health)
                        .tabItem { Label(Tab.health.title, systemImage: Tab.health.symbol) }
                }
            } else {
                NavigationStack {
                    OnboardWorkoutView()
                        .navigationTitle("Workout Setup")
                }
            }
        }
        .sheet(isPresented: $showScanSheet) {
            NavigationStack { MealScannerView() }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showVoiceSheet) {
            NavigationStack { MealVoiceLoggingView() }
                .presentationDetents([.medium, .large])
        }
    }

    private var dashboardRoot: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryHero
                quickActions
                quickLink("AI Mentor", subtitle: "Coaching, fatigue and recovery advice", symbol: "sparkles") { AIMentorView() }
                quickLink("Progress", subtitle: "Bodyweight and consistency trends", symbol: "chart.xyaxis.line") { WorkoutProgressDashboardView() }
                quickLink("Meal Planning", subtitle: "Personalized meals + groceries", symbol: "list.bullet.rectangle") { MealPlanView() }
                quickLink("Badges", subtitle: "Track your achievements", symbol: "rosette") { BadgesView() }
                quickLink("Settings", subtitle: "Goals, reminders and syncing", symbol: "gearshape.2.fill") { WorkoutsSettingsView() }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workouts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AIMentorView()
                } label: {
                    Image(systemName: "sparkles.rectangle.stack")
                }
            }
        }
    }

    private var summaryHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Today", systemImage: "sun.max.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Streak \(manager.streak.currentDays)d")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15), in: Capsule())
            }

            Text(todaySummary)
                .font(.title3.weight(.semibold))

            HStack(spacing: 12) {
                HomeStatPill(title: "Calories", value: "\(manager.nutrition.caloriesConsumed)", subtitle: "consumed", symbol: "flame.fill")
                HomeStatPill(title: "Workouts", value: "\(manager.progress.last?.workoutsCompleted ?? 0)", subtitle: "today", symbol: "figure.run")
                HomeStatPill(title: "Badges", value: "\(manager.badges.filter(\.isUnlocked).count)", subtitle: "unlocked", symbol: "rosette")
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [.blue.opacity(0.12), .mint.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button {
                showScanSheet = true
            } label: {
                quickIconLabel("Scan", symbol: "camera.viewfinder")
            }
            .buttonStyle(.plain)

            Button {
                showVoiceSheet = true
            } label: {
                quickIconLabel("Voice", symbol: "waveform.badge.mic")
            }
            .buttonStyle(.plain)
            quickIcon("Live", symbol: "timer") { LiveWorkoutView() }
            quickIcon("Log", symbol: "checklist") { WorkoutLoggingView() }
        }
    }

    private func quickIconLabel(_ title: String, symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.headline)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())
            Text(title)
                .font(.caption2.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func quickIcon<Destination: View>(_ title: String, symbol: String, @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.headline)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())
                Text(title)
                    .font(.caption2.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func quickLink<Destination: View>(_ title: String, subtitle: String, symbol: String, @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var todaySummary: String {
        guard let workout = manager.todayWorkout else {
            return "Your AI planner is ready to create your first personalized workout."
        }
        let done = workout.exercises.filter(\.isCompleted).count
        return "\(done)/\(workout.exercises.count) exercises complete • \(workout.estimatedDurationMinutes) min planned"
    }
}

private struct HomeStatPill: View {
    let title: String
    let value: String
    let subtitle: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: symbol)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
