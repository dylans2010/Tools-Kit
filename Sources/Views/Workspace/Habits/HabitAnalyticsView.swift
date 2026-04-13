import SwiftUI
import Charts

struct HabitAnalyticsView: View {
    @StateObject private var manager = HabitsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRange: AnalyticsRange = .week

    enum AnalyticsRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Range", selection: $selectedRange) {
                        ForEach(AnalyticsRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    overallCompletionCard
                    streakLeaderboard
                    trendChart
                    habitBreakdown
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var days: Int { selectedRange == .week ? 7 : 30 }

    private var overallCompletionCard: some View {
        let rates = manager.habits.map { manager.completionRate(for: $0, days: days) }
        let avg = rates.isEmpty ? 0.0 : rates.reduce(0, +) / Double(rates.count)
        return CardView {
            VStack(spacing: 12) {
                Text("Overall Completion Rate")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 16)
                    Circle()
                        .trim(from: 0, to: avg)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: avg)
                    Text("\(Int(avg * 100))%")
                        .font(.system(.title, design: .rounded).bold())
                }
                .frame(width: 120, height: 120)
                .frame(maxWidth: .infinity)

                Text("Based on last \(days) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .padding(.horizontal)
    }

    private var streakLeaderboard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Streak Leaders")
                    .font(.subheadline.bold())

                let sorted = manager.habits.sorted { $0.currentStreak > $1.currentStreak }
                ForEach(sorted.prefix(5)) { habit in
                    HStack {
                        Image(systemName: habit.icon)
                            .foregroundColor(Color(hex: habit.colorHex) ?? .blue)
                            .frame(width: 24)
                        Text(habit.name)
                            .font(.subheadline)
                        Spacer()
                        Label("\(habit.currentStreak)d", systemImage: "flame.fill")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                }

                if manager.habits.isEmpty {
                    Text("No habits tracked yet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }

    private var trendChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Completion Trend")
                    .font(.subheadline.bold())

                let data = trendData()
                Chart {
                    ForEach(data, id: \.date) { entry in
                        LineMark(
                            x: .value("Date", entry.label),
                            y: .value("Rate", entry.rate * 100)
                        )
                        .foregroundStyle(Color.accentColor)
                        AreaMark(
                            x: .value("Date", entry.label),
                            y: .value("Rate", entry.rate * 100)
                        )
                        .foregroundStyle(Color.accentColor.opacity(0.15))
                    }
                }
                .frame(height: 120)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: days > 7 ? 7 : 1)) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }

    private struct TrendEntry {
        let date: Date
        let label: String
        let rate: Double
    }

    private func trendData() -> [TrendEntry] {
        let calendar = Calendar.current
        guard !manager.habits.isEmpty else { return [] }
        return (0..<days).reversed().compactMap { offset -> TrendEntry? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let key = dateFormatter.string(from: date)
            let completed = manager.habits.filter { ($0.completionHistory[key] ?? 0) >= $0.targetCount }.count
            let rate = Double(completed) / Double(manager.habits.count)
            return TrendEntry(date: date, label: shortFormatter.string(from: date), rate: rate)
        }
    }

    private var habitBreakdown: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Habit Breakdown")
                    .font(.subheadline.bold())

                ForEach(manager.habits) { habit in
                    let rate = manager.completionRate(for: habit, days: days)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: habit.icon)
                                .foregroundColor(Color(hex: habit.colorHex) ?? .blue)
                            Text(habit.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(rate * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: rate)
                            .tint(Color(hex: habit.colorHex) ?? .blue)
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}
