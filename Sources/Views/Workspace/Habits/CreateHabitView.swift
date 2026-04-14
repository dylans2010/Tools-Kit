import SwiftUI

struct CreateHabitView: View {
    var existingHabit: Habit? = nil
    var onSave: (Habit) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var icon: String = "checkmark.circle"
    @State private var colorHex: String = "#007AFF"
    @State private var frequency: HabitFrequency = .daily
    @State private var targetCount: Int = 1
    @State private var showingIconPicker = false

    private var isEditing: Bool { existingHabit != nil }

    private let presetColors: [(String, Color)] = [
        ("#007AFF", .blue), ("#34C759", .green), ("#FF3B30", .red),
        ("#FF9500", .orange), ("#AF52DE", .purple), ("#FF2D55", .pink),
        ("#5AC8FA", .cyan), ("#FFCC00", .yellow)
    ]

    private let presetIcons = [
        "checkmark.circle", "flame.fill", "heart.fill", "drop.fill",
        "figure.run", "moon.fill", "book.fill", "pencil",
        "fork.knife", "dumbbell", "leaf.fill", "brain.head.profile",
        "music.note", "sun.max.fill", "bed.double.fill", "bicycle"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Details") {
                    HStack {
                        Button {
                            showingIconPicker = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill((Color(hex: colorHex) ?? .blue).opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: colorHex) ?? .blue)
                            }
                        }
                        .buttonStyle(.plain)
                        TextField("Habit Name", text: $name)
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    Stepper("Target: \(targetCount)x Per Day", value: $targetCount, in: 1...20)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(presetColors, id: \.0) { hex, color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(0.4), lineWidth: colorHex == hex ? 2.5 : 0)
                                        .padding(2)
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button(action: save) {
                        Text(isEditing ? "Save Changes" : "Create Habit")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                iconPickerSheet
            }
            .onAppear {
                if let h = existingHabit {
                    name = h.name
                    icon = h.icon
                    colorHex = h.colorHex
                    frequency = h.frequency
                    targetCount = h.targetCount
                }
            }
        }
    }

    private var iconPickerSheet: some View {
        NavigationStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(presetIcons, id: \.self) { iconName in
                    Button {
                        icon = iconName
                        showingIconPicker = false
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(icon == iconName ? (Color(hex: colorHex) ?? .blue).opacity(0.2) : Color(.secondarySystemBackground))
                            Image(systemName: iconName)
                                .font(.system(size: 26))
                                .foregroundColor(icon == iconName ? (Color(hex: colorHex) ?? .blue) : .primary)
                        }
                        .frame(height: 64)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .navigationTitle("Pick Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingIconPicker = false }
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var habit = existingHabit ?? Habit(name: trimmed)
        habit.name = trimmed
        habit.icon = icon
        habit.colorHex = colorHex
        habit.frequency = frequency
        habit.targetCount = targetCount
        onSave(habit)
        dismiss()
    }
}
