import SwiftUI
import Charts

struct HabitDetailView: View {
    let habit: Habit
    @ObservedObject var manager: HabitsManager
    @State private var showingEdit = false

    private var accentColor: Color { Color(hex: habit.colorHex) ?? .blue }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                statsRow
                last30DaysChart
                completionCalendar
            }
            .padding(.vertical, 8)
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            CreateHabitView(manager: manager, editingHabit: habit)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(accentColor.opacity(0.15)).frame(width: 72, height: 72)
                Image(systemName: habit.icon).font(.largeTitle).foregroundColor(accentColor)
            }
            Text(habit.name).font(.title2.bold())
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundColor(.orange)
                Text("\(habit.currentStreak) day streak").font(.subheadline).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCell("Current\nStreak", value: "\(habit.currentStreak)", unit: "days", color: .orange)
            statCell("Longest\nStreak", value: "\(habit.longestStreak)", unit: "days", color: .purple)
            statCell("Weekly\nRate", value: String(format: "%.0f%%", habit.weeklyCompletionRate() * 100), unit: "", color: accentColor)
        }
        .padding(.horizontal)
    }

    private func statCell(_ title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title2.bold()).foregroundColor(color)
            if !unit.isEmpty { Text(unit).font(.caption2).foregroundColor(.secondary) }
            Text(title).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    // MARK: - Last 30 Days Chart

    private var last30DaysChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 30 Days").font(.headline).padding(.horizontal)
            let data = last30Days()
            Chart(data, id: \.0) { day, count in
                BarMark(x: .value("Day", day), y: .value("Count", count))
                    .foregroundStyle(accentColor.gradient)
                    .cornerRadius(2)
            }
            .frame(height: 100)
            .chartYAxis(.hidden)
            .padding(.horizontal)
        }
    }

    private func last30Days() -> [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "d"
        return (0..<30).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let key = formatter.string(from: date)
            return (shortFormatter.string(from: date), habit.completionHistory[key] ?? 0)
        }
    }

    // MARK: - Mini Calendar

    private var completionCalendar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Completion History").font(.headline).padding(.horizontal)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(calendarCells(), id: \.0) { dateStr, count in
                    let done = count >= habit.targetCount
                    RoundedRectangle(cornerRadius: 4)
                        .fill(done ? accentColor : Color(.systemGray5))
                        .frame(height: 24)
                        .overlay(
                            Text(dateStr)
                                .font(.system(size: 8))
                                .foregroundColor(done ? .white : .secondary)
                        )
                }
            }
            .padding(.horizontal)
        }
    }

    private func calendarCells() -> [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        return (0..<56).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let key = formatter.string(from: date)
            return (dayFormatter.string(from: date), habit.completionHistory[key] ?? 0)
        }
    }
}
