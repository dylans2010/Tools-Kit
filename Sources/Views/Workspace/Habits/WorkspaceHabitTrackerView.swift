import SwiftUI
import Charts

struct WorkspaceHabitTrackerView: View {
    @StateObject private var manager = HabitsManager.shared
    @State private var showingCreate = false
    @State private var selectedHabit: Habit?
    @State private var showingAnalytics = false
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var aiInsights: HabitsManager.AIHabitInsights?

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    let completed = manager.habits.filter { $0.isCompletedToday() }.count
                    let habitCount = manager.habits.count
                    let safeTotal = max(habitCount, 1)
                    HabitStatLabel(label: "Done", value: "\(completed)/\(habitCount)")
                    HabitStatLabel(label: "Rate", value: "\(Int((Double(completed) / Double(safeTotal)) * 100))%")
                    HabitStatLabel(label: "Streaking", value: "\(manager.habits.filter { $0.currentStreak > 0 }.count)")
                }
            } header: {
                Text("Summary")
            }

            Section {
                TextField("Describe your goals to get habit recommendations…", text: $aiPrompt, axis: .vertical)

                HStack(spacing: 8) {
                    Button("Morning") { runAI(with: "Design a realistic morning routine for focus, fitness, and consistency.") }
                        .buttonStyle(.bordered)
                    Button("Break Bad") { runAI(with: "Give a replacement habit strategy to break a bad habit pattern.") }
                        .buttonStyle(.bordered)
                    Button("Recovery") { runAI(with: "Create a 7-day streak recovery plan after missed days.") }
                        .buttonStyle(.bordered)
                }

                Button("Generate Coaching", action: runAI)
                    .buttonStyle(.borderedProminent)
                    .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)

                if aiLoading {
                    ProgressView("Analyzing your habits…")
                } else if let aiError {
                    Label(aiError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if let aiInsights {
                    insightList("Suggested Habits", aiInsights.suggestedHabits)
                    insightList("Optimization", aiInsights.optimizationTips)
                }
            } header: {
                Text("AI Coach")
            }

            if manager.habits.isEmpty {
                ContentUnavailableView {
                    Label("No Habits Yet", systemImage: "flame")
                } description: {
                    Text("Add habits or ask AI for recommendations based on your goals.")
                } actions: {
                    Button("Add Habit") { showingCreate = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                Section {
                    ForEach(manager.habits) { habit in
                        HabitRow(habit: habit, manager: manager) { selectedHabit = habit }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { manager.deleteHabit(habit) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text("Your Habits")
                }
            }
        }
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !manager.habits.isEmpty {
                    Button { showingAnalytics = true } label: {
                        Image(systemName: "chart.bar")
                    }
                }
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateHabitView { manager.addHabit($0) }
        }
        .sheet(isPresented: $showingAnalytics) {
            HabitAnalyticsView()
        }
        .sheet(item: $selectedHabit) { habit in
            NavigationStack { HabitDetailView(habit: habit) }
        }
    }

    private func insightList(_ title: String, _ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func runAI() {
        runAI(with: aiPrompt)
    }

    private func runAI(with input: String) {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                let insights = try await manager.generateHabitInsights(goalPrompt: prompt)
                await MainActor.run {
                    aiInsights = insights
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Could not generate coaching tips. Try a goal with timeline and current obstacles."
                    aiLoading = false
                }
            }
        }
    }
}

private struct HabitRow: View {
    let habit: Habit
    @ObservedObject var manager: HabitsManager
    let onTap: () -> Void

    private var completedToday: Bool { habit.isCompletedToday() }
    private var todayCount: Int { manager.todayCount(for: habit) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: habit.icon)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.body.weight(.semibold))
                    HStack(spacing: 6) {
                        Label("\(habit.currentStreak)d", systemImage: "flame")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label("\(todayCount)/\(habit.targetCount)", systemImage: "target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(min(todayCount, habit.targetCount)), total: Double(habit.targetCount))
                }
                Spacer()
                Button {
                    manager.increment(habit: habit)
                } label: {
                    Image(systemName: completedToday ? "checkmark.circle.fill" : "plus.circle")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct HabitStatLabel: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
