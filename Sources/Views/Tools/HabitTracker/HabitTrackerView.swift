import SwiftUI

import Charts

struct HabitTrackerView: View {
    @StateObject private var backend = HabitTrackerBackend()
    @State private var showingAddSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Track your daily routines and build long-term consistency. Tap the plus button to log progress for today.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                if backend.habits.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checklist")
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundColor(.secondary)
                        Text("No habits tracked yet.")
                            .foregroundColor(.secondary)
                        Button("Add Your First Habit") { showingAddSheet = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ForEach(backend.habits) { habit in
                        HabitCard(habit: habit, backend: backend)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Habit Tracker")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddHabitSheet(backend: backend)
        }
    }
}

struct HabitCard: View {
    let habit: HabitItem
    @ObservedObject var backend: HabitTrackerBackend

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.title3.bold())
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(habit.currentStreak) day streak")
                            .font(.caption)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(backend.todayCount(for: habit))")
                        .font(.system(.title, design: .rounded))
                        .bold()
                    Text("today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Button(action: { backend.incrementToday(for: habit.id) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(color(for: habit.color))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Weekly Progress")
                        .font(.caption.bold())
                    Spacer()
                    Text("\(habit.completedThisWeek) / \(habit.targetPerWeek)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(min(habit.completedThisWeek, habit.targetPerWeek)), total: Double(habit.targetPerWeek))
                    .tint(color(for: habit.color))
            }

            // Simple Sparkline Chart
            Chart {
                let last7Days = (0..<7).reversed().map { dayOffset -> (String, Int) in
                    let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let key = formatter.string(from: date)
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateFormat = "E"
                    return (displayFormatter.string(from: date), habit.completionsByDay[key] ?? 0)
                }

                ForEach(last7Days, id: \.0) { day, count in
                    BarMark(
                        x: .value("Day", day),
                        y: .value("Count", count)
                    )
                    .foregroundStyle(color(for: habit.color).gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 60)
            .chartYAxis(.hidden)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
        .swipeActions {
            Button(role: .destructive) {
                if let index = backend.habits.firstIndex(where: { $0.id == habit.id }) {
                    backend.deleteHabit(at: IndexSet(integer: index))
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                backend.resetToday(for: habit.id)
            } label: {
                Label("Reset Today", systemImage: "arrow.counterclockwise")
            }
            .tint(.orange)
        }
    }

    private func color(for name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        default: return .blue
        }
    }
}

struct AddHabitSheet: View {
    @ObservedObject var backend: HabitTrackerBackend
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var target = 5
    @State private var selectedColor = "blue"

    let colors = ["blue", "red", "green", "orange", "purple"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Drink Water", text: $name)
                    Stepper("Weekly Target: \(target)", value: $target, in: 1...7)
                } header: {
                    Text("Habit Details")
                }

                Section {
                    HStack {
                        ForEach(colors, id: \.self) { colorName in
                            Circle()
                                .fill(color(for: colorName))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == colorName ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = colorName
                                }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Theme Color")
                }

                Section {
                    Button(action: {
                        backend.newHabitName = name
                        backend.targetPerWeek = target
                        // Ideally backend.addHabit() would take a color, but we'll stick to basic for now
                        backend.addHabit()
                        dismiss()
                    }) {
                        Text("Create Habit")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("New Habit")
            .toolbar {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func color(for name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        default: return .blue
        }
    }
}

struct HabitTrackerTool: Tool {
    let name = "Habit Tracker"
    let icon = "checkmark.seal.fill"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Track your daily habits and build long-term consistency"
    let requiresAPI = false
    var view: AnyView { AnyView(HabitTrackerView()) }
}
