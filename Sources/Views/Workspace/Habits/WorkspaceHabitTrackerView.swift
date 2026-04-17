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
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                Section {
                    VStack(spacing: 16) {
                        summaryHeader
                        aiInsightsCard
                        if manager.habits.isEmpty {
                            EmptyStateView(
                                icon: "flame.fill",
                                title: "No Habits Yet",
                                message: "Add habits or ask AI for recommendations based on your goals.",
                                action: { showingCreate = true },
                                actionLabel: "Add Habit"
                            )
                        } else {
                            VStack(spacing: 10) {
                                ForEach(manager.habits) { habit in
                                    HabitRowCard(habit: habit, manager: manager) {
                                        selectedHabit = habit
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                } header: {
                    HStack {
                        Text("Habits")
                            .font(.title3.weight(.semibold))
                        Spacer()
                        if !manager.habits.isEmpty {
                            Button {
                                showingAnalytics = true
                            } label: {
                                Label("Analytics", systemImage: "chart.bar")
                            }
                            .buttonStyle(.bordered)
                        }
                        Button {
                            showingCreate = true
                        } label: {
                            Label("New", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .overlay(Divider(), alignment: .bottom)
                }
            }
        }
        .navigationTitle("Habits")
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

    private var summaryHeader: some View {
        HStack(spacing: 8) {
            let completed = manager.habits.filter { $0.isCompletedToday() }.count
            let total = max(manager.habits.count, 1)
            StatPill(label: "Done", value: "\(completed)/\(manager.habits.count)", color: .green)
            StatPill(label: "Rate", value: "\(Int((Double(completed) / Double(total)) * 100))%", color: .blue)
            StatPill(label: "Streaking", value: "\(manager.habits.filter { $0.currentStreak > 0 }.count)", color: .orange)
        }
    }

    private var aiInsightsCard: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("AI Habit Coach")
                    .font(.headline)
                TextField("Describe your goals to get habit recommendations…", text: $aiPrompt)
                    .textFieldStyle(.roundedBorder)
                Button("Generate Coaching", action: runAI)
                    .buttonStyle(.borderedProminent)
                    .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)

                if aiLoading {
                    WorkspaceSkeletonLine()
                    WorkspaceSkeletonLine(widthRatio: 0.7)
                } else if let aiError {
                    Text(aiError)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let aiInsights {
                    insightList("Suggested Habits", aiInsights.suggestedHabits)
                    insightList("Optimization", aiInsights.optimizationTips)
                }
            }
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
        let prompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    aiError = "AI habits response was invalid. Please refine your goal."
                    aiLoading = false
                }
            }
        }
    }
}

struct HabitRowCard: View {
    let habit: Habit
    @ObservedObject var manager: HabitsManager
    let onTap: () -> Void

    var completedToday: Bool { habit.isCompletedToday() }
    var todayCount: Int { manager.todayCount(for: habit) }
    var habitColor: Color { Color(hex: habit.colorHex) ?? .blue }

    var body: some View {
        WorkspaceSurfaceCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: habit.icon)
                        .foregroundStyle(habitColor)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.name)
                        .font(.body.weight(.semibold))
                        .onTapGesture(perform: onTap)
                    HStack(spacing: 6) {
                        WorkspaceStatusBadge(title: "\(habit.currentStreak) day streak", color: .orange)
                        WorkspaceStatusBadge(title: "\(todayCount)/\(habit.targetCount)", color: habitColor)
                    }
                    ProgressView(value: Double(min(todayCount, habit.targetCount)), total: Double(habit.targetCount))
                        .tint(habitColor)
                }
                Spacer()
                Button {
                    manager.increment(habit: habit)
                } label: {
                    Image(systemName: completedToday ? "checkmark.circle.fill" : "plus.circle")
                        .font(.title2)
                        .foregroundStyle(completedToday ? habitColor : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { manager.deleteHabit(habit) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
