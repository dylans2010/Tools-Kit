import SwiftUI
import Charts

struct WorkspaceHabitTrackerView: View {
    @StateObject private var manager = HabitsManager.shared
    @State private var showingCreate = false
    @State private var selectedHabit: Habit? = nil
    @State private var showingAnalytics = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryHeader

                if manager.habits.isEmpty {
                    EmptyStateView(
                        icon: "flame.fill",
                        title: "No Habits Yet",
                        message: "Build lasting routines by tracking your daily habits.",
                        action: { showingCreate = true },
                        actionLabel: "Add Habit"
                    )
                } else {
                    todaySection
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !manager.habits.isEmpty {
                    Button {
                        showingAnalytics = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
                Button {
                    showingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateHabitView { habit in
                manager.addHabit(habit)
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            HabitAnalyticsView()
        }
        .sheet(item: $selectedHabit) { habit in
            NavigationStack {
                HabitDetailView(habit: habit)
            }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateFormatter.string(from: Date()))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            let completed = manager.habits.filter { $0.isCompletedToday() }.count
            let total = manager.habits.count
            if total > 0 {
                HStack(spacing: 16) {
                    StatPill(label: "Done Today", value: "\(completed)/\(total)", color: .green)
                    StatPill(label: "Completion", value: "\(Int(Double(completed)/Double(total)*100))%", color: .blue)
                    let streaking = manager.habits.filter { $0.currentStreak > 0 }.count
                    StatPill(label: "Streaking", value: "\(streaking)", color: .orange)
                }
                .padding(.horizontal)
            }
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Habits")
                .font(.headline)
                .padding(.horizontal)

            ForEach(manager.habits) { habit in
                HabitRowCard(habit: habit, manager: manager) {
                    selectedHabit = habit
                }
            }
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded).bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(12)
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
        VStack {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: habit.icon)
                        .font(.system(size: 20))
                        .foregroundColor(habitColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.subheadline.bold())
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(habit.currentStreak) day streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("·")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("\(todayCount)/\(habit.targetCount) today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: Double(min(todayCount, habit.targetCount)), total: Double(habit.targetCount))
                        .tint(habitColor)
                }
                .onTapGesture { onTap() }

                Spacer()

                Button {
                    manager.increment(habit: habit)
                } label: {
                    Image(systemName: completedToday ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 32))
                        .foregroundColor(completedToday ? habitColor : .secondary)
                        .animation(.spring(), value: completedToday)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                manager.deleteHabit(habit)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                manager.resetToday(habit: habit)
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading) {
            Button {
                manager.decrement(habit: habit)
            } label: {
                Label("Undo", systemImage: "minus.circle")
            }
            .tint(.gray)
        }
    }
}
