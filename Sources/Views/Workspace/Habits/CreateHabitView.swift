import SwiftUI

struct CreateHabitView: View {
    @ObservedObject var manager: HabitsManager
    @Environment(\.dismiss) private var dismiss

    var editingHabit: Habit?

    @State private var name = ""
    @State private var icon = "star.fill"
    @State private var colorHex = "3B82F6"
    @State private var frequency: Habit.HabitFrequency = .daily
    @State private var targetCount = 1

    private let icons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill", "drop.fill",
        "leaf.fill", "moon.fill", "sun.max.fill", "figure.run", "dumbbell.fill",
        "book.fill", "pencil", "music.note", "paintbrush.fill", "laptopcomputer"
    ]

    private let colorOptions: [(String, String)] = [
        ("Blue", "3B82F6"), ("Green", "22C55E"), ("Purple", "A855F7"),
        ("Orange", "F97316"), ("Red", "EF4444"), ("Pink", "EC4899"),
        ("Teal", "14B8A6"), ("Yellow", "EAB308")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Drink Water", text: $name)
                }

                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(icons, id: \.self) { ic in
                                Button {
                                    icon = ic
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(icon == ic ? (Color(hex: colorHex) ?? .blue) : Color(.systemGray5))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: ic)
                                            .foregroundColor(icon == ic ? .white : .primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(colorOptions, id: \.1) { name, hex in
                                Button { colorHex = hex } label: {
                                    Circle()
                                        .fill(Color(hex: hex) ?? .blue)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle().stroke(Color.primary, lineWidth: colorHex == hex ? 3 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Habit.HabitFrequency.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Daily Target") {
                    Stepper("\(targetCount) time\(targetCount == 1 ? "" : "s") per day", value: $targetCount, in: 1...20)
                }
            }
            .navigationTitle(editingHabit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editingHabit == nil ? "Create" : "Save") { save() }
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let h = editingHabit {
                    name = h.name
                    icon = h.icon
                    colorHex = h.colorHex
                    frequency = h.frequency
                    targetCount = h.targetCount
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if var existing = editingHabit {
            existing.name = trimmed
            existing.icon = icon
            existing.colorHex = colorHex
            existing.frequency = frequency
            existing.targetCount = targetCount
            manager.updateHabit(existing)
        } else {
            let habit = Habit(name: trimmed, icon: icon, colorHex: colorHex, frequency: frequency, targetCount: targetCount)
            manager.addHabit(habit)
        }
        dismiss()
    }
}
