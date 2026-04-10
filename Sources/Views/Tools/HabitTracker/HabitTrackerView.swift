import SwiftUI

struct HabitTrackerView: View {
    @State private var habits = ["Drink Water", "Read 10 mins", "Exercise"]
    @State private var completedToday: Set<String> = []

    var body: some View {
        List {
            ForEach(habits, id: \.self) { habit in
                HStack {
                    Text(habit)
                    Spacer()
                    Button(action: {
                        if completedToday.contains(habit) {
                            completedToday.remove(habit)
                        } else {
                            completedToday.insert(habit)
                        }
                    }) {
                        Image(systemName: completedToday.contains(habit) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(completedToday.contains(habit) ? .green : .gray)
                            .font(.title2)
                    }
                }
                .padding(.vertical, 4)
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
