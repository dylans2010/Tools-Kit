import SwiftUI

struct WorkspaceHabitTrackerView: View {
    @StateObject private var manager = HabitsManager.shared
    @State private var showingCreate = false
    @State private var showingAI = false
    @State private var aiSuggestion = ""
    @State private var isLoadingAI = false
    @State private var selectedHabit: Habit?
    @State private var showingHabitDetail = false
    @State private var showingAnalytics = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCards
                todaySection
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    Button { showingAI = true } label: { Image(systemName: "sparkles") }
                    Button { showingCreate = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showingCreate) { CreateHabitView(manager: manager) }
        .sheet(isPresented: $showingAI) { aiSheet }
        .navigationDestination(isPresented: $showingHabitDetail) {
            if let habit = selectedHabit {
                HabitDetailView(habit: habit, manager: manager)
            }
        }
        .navigationDestination(isPresented: $showingAnalytics) {
            HabitAnalyticsView(manager: manager)
        }
    }

    // MARK: - Header

    private var headerCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                statCard("Today", value: "\(completedToday)/\(manager.habits.count)", icon: "checkmark.circle.fill", color: .green)
                statCard("Streak", value: "\(bestStreak)", icon: "flame.fill", color: .orange)
                statCard("Total", value: "\(manager.habits.count)", icon: "list.bullet", color: .blue)
                Button {
                    showingAnalytics = true
                } label: {
                    statCard("Analytics", value: "View", icon: "chart.bar.fill", color: .purple)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
    }

    private func statCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Spacer()
            }
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(width: 110)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private var completedToday: Int {
        manager.habits.filter { $0.completedToday() }.count
    }

    private var bestStreak: Int {
        manager.habits.map { $0.currentStreak }.max() ?? 0
    }

    // MARK: - Today's Habits

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Habits")
                .font(.headline)
                .padding(.horizontal)

            if manager.habits.isEmpty {
                EmptyStateView(
                    icon: "checkmark.seal",
                    title: "No Habits Yet",
                    message: "Add your first habit to start tracking.",
                    action: { showingCreate = true },
                    actionLabel: "Add Habit"
                )
            } else {
                ForEach(manager.habits) { habit in
                    HabitRowView(habit: habit, manager: manager) {
                        selectedHabit = habit
                        showingHabitDetail = true
                    }
                }
            }
        }
    }

    // MARK: - AI Sheet

    private var aiSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoadingAI {
                    ProgressView("Generating habit suggestions…")
                        .padding()
                } else if !aiSuggestion.isEmpty {
                    ScrollView {
                        Text(aiSuggestion)
                            .padding()
                            .font(.body)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                        Text("AI Habit Coach")
                            .font(.title2.bold())
                        Text("Get personalized habit suggestions based on your current tracking patterns.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                Spacer()
                Button {
                    generateAISuggestions()
                } label: {
                    Label("Get Suggestions", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding()
                .disabled(isLoadingAI)
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { showingAI = false }
                }
            }
        }
    }

    private func generateAISuggestions() {
        isLoadingAI = true
        let habitNames = manager.habits.map { $0.name }.joined(separator: ", ")
        let prompt = habitNames.isEmpty
            ? "Suggest 5 powerful daily habits for a productive and healthy lifestyle. For each, give a name, brief description, and recommended frequency."
            : "I'm tracking these habits: \(habitNames). Analyze my routine and suggest 3 improvements or new complementary habits to add."
        Task {
            do {
                let result = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: "You are a habit coach and productivity expert. Give actionable, specific advice."
                )
                await MainActor.run {
                    aiSuggestion = result
                    isLoadingAI = false
                }
            } catch {
                await MainActor.run {
                    aiSuggestion = "Could not load suggestions. Please check your AI settings."
                    isLoadingAI = false
                }
            }
        }
    }
}

// MARK: - Habit Row

struct HabitRowView: View {
    let habit: Habit
    @ObservedObject var manager: HabitsManager
    let onTap: () -> Void

    private var accentColor: Color { Color(hex: habit.colorHex) ?? .blue }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: habit.icon)
                        .foregroundColor(accentColor)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name).font(.headline)
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundColor(.orange).font(.caption)
                        Text("\(habit.currentStreak) day streak").font(.caption).foregroundColor(.secondary)
                    }
                    ProgressView(value: Double(min(habit.todayCount(), habit.targetCount)), total: Double(habit.targetCount))
                        .tint(accentColor)
                }

                Spacer()

                VStack(spacing: 8) {
                    Text("\(habit.todayCount())/\(habit.targetCount)")
                        .font(.caption.bold())
                        .foregroundColor(habit.completedToday() ? .green : .primary)
                    Button {
                        manager.increment(habit)
                    } label: {
                        Image(systemName: habit.completedToday() ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(habit.completedToday() ? .green : accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { manager.deleteHabit(habit) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
