import SwiftUI

struct HabitTrackerView: View {
    @StateObject private var backend = HabitTrackerBackend()

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                TextField("New habit", text: $backend.newHabitName)
                    .textFieldStyle(.roundedBorder)
                Stepper("\(backend.targetPerWeek)x", value: $backend.targetPerWeek, in: 1...14)
                    .frame(width: 110)
                Button(action: backend.addHabit) {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .padding(.horizontal)

            List {
                ForEach(backend.habits) { habit in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(habit.name).font(.headline)
                            Spacer()
                            Text("Week: \(habit.completedThisWeek)/\(habit.targetPerWeek)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        ProgressView(value: min(Double(habit.completedThisWeek), Double(habit.targetPerWeek)), total: Double(habit.targetPerWeek))

                        HStack {
                            Text("Today: \(backend.todayCount(for: habit))")
                                .font(.subheadline)
                            Spacer()
                            Button("+1") { backend.incrementToday(for: habit.id) }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            Button("Reset") { backend.resetToday(for: habit.id) }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: backend.deleteHabit)
            }
        }
        .navigationTitle("Habit Tracker")
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
