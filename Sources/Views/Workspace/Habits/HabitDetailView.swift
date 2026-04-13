import SwiftUI
import Charts

struct HabitDetailView: View {
    @State var habit: Habit
    @StateObject private var manager = HabitsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false

    private var habitColor: Color { Color(hex: habit.colorHex) ?? .blue }
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                streakSection
                last30DaysChart
                calendarGrid
            }
            .padding()
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            CreateHabitView(existingHabit: habit) { updated in
                manager.updateHabit(updated)
                habit = updated
            }
        }
        .onReceive(manager.$habits) { habits in
            if let updated = habits.first(where: { $0.id == habit.id }) {
                habit = updated
            }
        }
    }

    private var headerCard: some View {
        CardView {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: habit.icon)
                        .font(.system(size: 28))
                        .foregroundColor(habitColor)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.name)
                        .font(.title3.bold())
                    Label(habit.frequency.rawValue, systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("Target: \(habit.targetCount)x per day", systemImage: "target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
        }
    }

    private var streakSection: some View {
        HStack(spacing: 16) {
            streakCard(title: "Current Streak", value: "\(habit.currentStreak)", icon: "flame.fill", color: .orange)
            streakCard(title: "Longest Streak", value: "\(habit.longestStreak)", icon: "trophy.fill", color: .yellow)
            streakCard(title: "7-Day Rate", value: "\(Int(habit.weeklyCompletionRate() * 100))%", icon: "chart.bar.fill", color: habitColor)
        }
    }

    private func streakCard(title: String, value: String, icon: String, color: Color) -> some View {
        CardView {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(value)
                    .font(.system(.title2, design: .rounded).bold())
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private var last30DaysChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 30 Days")
                    .font(.headline)

                let data = habit.last30DayCounts()
                Chart {
                    ForEach(data.suffix(30), id: \.0) { day, count in
                        BarMark(
                            x: .value("Day", day),
                            y: .value("Count", count)
                        )
                        .foregroundStyle(count >= habit.targetCount ? habitColor.gradient : Color.secondary.opacity(0.3).gradient)
                        .cornerRadius(3)
                    }
                }
                .frame(height: 100)
                .chartXAxis(.hidden)
            }
            .padding()
        }
    }

    private var calendarGrid: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Completion History")
                    .font(.headline)

                let weeks = last12Weeks()
                let days = ["S", "M", "T", "W", "T", "F", "S"]

                HStack(spacing: 4) {
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                ForEach(0..<weeks.count, id: \.self) { weekIdx in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { dayIdx in
                            let entry = weeks[weekIdx][dayIdx]
                            let count = entry.count
                            let inRange = entry.inRange
                            RoundedRectangle(cornerRadius: 3)
                                .fill(inRange ? (count >= habit.targetCount ? habitColor : (count > 0 ? habitColor.opacity(0.4) : Color(.systemFill))) : Color.clear)
                                .frame(height: 22)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private struct DayEntry {
        let count: Int
        let inRange: Bool
    }

    private func last12Weeks() -> [[DayEntry]] {
        let calendar = Calendar.current
        let today = Date()
        var result: [[DayEntry]] = []
        for weekOffset in stride(from: -11, through: 0, by: 1) {
            var week: [DayEntry] = []
            for dayOffset in 0..<7 {
                let totalOffset = weekOffset * 7 + dayOffset
                if let date = calendar.date(byAdding: .day, value: totalOffset, to: today) {
                    let key = dateFormatter.string(from: date)
                    let count = habit.completionHistory[key] ?? 0
                    week.append(DayEntry(count: count, inRange: date <= today))
                } else {
                    week.append(DayEntry(count: 0, inRange: false))
                }
            }
            result.append(week)
        }
        return result
    }
}
