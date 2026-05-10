import SwiftUI

struct CreateHabitView: View {
    var existingHabit: Habit?
    var onSave: (Habit) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "star"
    @State private var selectedColor = "#007AFF"
    @State private var frequency: HabitFrequency = .daily
    @State private var targetCount = 1

    init(existingHabit: Habit? = nil, onSave: @escaping (Habit) -> Void) {
        self.existingHabit = existingHabit
        self.onSave = onSave
        _name = State(initialValue: existingHabit?.name ?? "")
        _description = State(initialValue: existingHabit?.description ?? "")
        _selectedIcon = State(initialValue: existingHabit?.icon ?? "star")
        _selectedColor = State(initialValue: existingHabit?.colorHex ?? "#007AFF")
        _frequency = State(initialValue: existingHabit?.frequency ?? .daily)
        _targetCount = State(initialValue: existingHabit?.targetCount ?? 1)
    }

    private let presetIcons = [
        "star", "flame", "heart", "bolt",
        "drop", "book", "figure.walk", "brain.head.profile",
        "moon", "sun.max", "cup.and.saucer", "leaf"
    ]

    private let presetColors = [
        "#007AFF", "#34C759", "#FF3B30", "#FF9500",
        "#AF52DE", "#FF2D55", "#5AC8FA", "#FFCC00"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name", text: $name)
                    TextField("Description (Optional)", text: $description)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(presetIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(presetColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .accentColor)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary, lineWidth: selectedColor == hex ? 2.5 : 0)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue.capitalized).tag(freq)
                        }
                    }
                    Stepper("Daily Target: \(targetCount)", value: $targetCount, in: 1...20)
                }

                Section {
                    Button(action: save) {
                        Text(existingHabit == nil ? "Create Habit" : "Save Changes")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(existingHabit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var habit = Habit(
            name: trimmed,
            description: description,
            icon: selectedIcon,
            colorHex: selectedColor,
            frequency: frequency,
            targetCount: targetCount
        )
        if let existingHabit {
            habit.id = existingHabit.id
            habit.createdAt = existingHabit.createdAt
            habit.completionHistory = existingHabit.completionHistory
        }
        onSave(habit)
        dismiss()
    }
}
