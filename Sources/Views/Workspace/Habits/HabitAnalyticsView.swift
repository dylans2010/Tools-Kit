import SwiftUI
import Charts

struct HabitAnalyticsView: View {
    @ObservedObject var manager: HabitsManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                overviewCards
                weeklyCompletionChart
                streakLeaderboard
                consistencySection
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Overview

    private var overviewCards: some View {
        HStack(spacing: 12) {
            analyticsCard("Total Habits", value: "\(manager.habits.count)", icon: "list.bullet", color: .blue)
            analyticsCard("Completed Today", value: "\(completedToday)", icon: "checkmark.circle.fill", color: .green)
            analyticsCard("Best Streak", value: "\(bestStreak)", icon: "flame.fill", color: .orange)
        }
        .padding(.horizontal)
    }

    private var completedToday: Int {
        manager.habits.filter { $0.completedToday() }.count
    }

    private var bestStreak: Int {
        manager.habits.map { $0.currentStreak }.max() ?? 0
    }

    private func analyticsCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    // MARK: - Weekly Chart

    private var weeklyCompletionChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Completion Trend").font(.headline).padding(.horizontal)
            let data = weeklyData()
            Chart {
                ForEach(data, id: \.0) { day, count in
                    LineMark(x: .value("Day", day), y: .value("Completed", count))
                        .foregroundStyle(.blue.gradient)
                        .symbol(Circle())
                    AreaMark(x: .value("Day", day), y: .value("Completed", count))
                        .foregroundStyle(.blue.opacity(0.1))
                }
            }
            .frame(height: 150)
            .chartYAxis { AxisMarks(position: .leading) }
            .padding(.horizontal)
        }
    }

    private func weeklyData() -> [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let key = formatter.string(from: date)
            let count = manager.habits.filter { ($0.completionHistory[key] ?? 0) >= $0.targetCount }.count
            return (dayFormatter.string(from: date), count)
        }
    }

    // MARK: - Streak Leaderboard

    private var streakLeaderboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Streak Leaderboard").font(.headline).padding(.horizontal)
            let sorted = manager.habits.sorted { $0.currentStreak > $1.currentStreak }
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, habit in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    ZStack {
                        Circle().fill((Color(hex: habit.colorHex) ?? .blue).opacity(0.15)).frame(width: 36, height: 36)
                        Image(systemName: habit.icon).foregroundColor(Color(hex: habit.colorHex) ?? .blue).font(.subheadline)
                    }
                    Text(habit.name).font(.subheadline)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").foregroundColor(.orange).font(.caption)
                        Text("\(habit.currentStreak)").font(.subheadline.bold())
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Consistency

    private var consistencySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Consistency").font(.headline).padding(.horizontal)
            ForEach(manager.habits) { habit in
                HStack {
                    Text(habit.name).font(.subheadline).lineLimit(1)
                    Spacer()
                    ProgressView(value: habit.weeklyCompletionRate())
                        .tint(Color(hex: habit.colorHex) ?? .blue)
                        .frame(width: 120)
                    Text(String(format: "%.0f%%", habit.weeklyCompletionRate() * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.horizontal)
            }
        }
    }
}
