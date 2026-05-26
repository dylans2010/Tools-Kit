import SwiftUI

struct CalendarEventCategoryManagerView: View {
    @State private var categories: [EventCategory] = [
        EventCategory(name: "Work", colorHex: "#007AFF", icon: "briefcase.fill"),
        EventCategory(name: "Personal", colorHex: "#34C759", icon: "person.fill"),
        EventCategory(name: "Health", colorHex: "#FF3B30", icon: "heart.fill"),
        EventCategory(name: "Education", colorHex: "#AF52DE", icon: "book.fill")
    ]
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var selectedColor: Color = .blue

    struct EventCategory: Identifiable, Codable {
        let id: UUID
        var name: String
        var colorHex: String
        var icon: String

        var color: Color { Color(hex: colorHex) }

        init(id: UUID = UUID(), name: String, colorHex: String = "#007AFF", icon: String = "tag.fill") {
            self.id = id
            self.name = name
            self.colorHex = colorHex
            self.icon = icon
        }
    }

    var body: some View {
        List {
            Section("Active Categories") {
                ForEach(categories) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundStyle(category.color)
                            .frame(width: 30)
                        Text(category.name)
                            .font(.subheadline.bold())
                        Spacer()
                    }
                }
                .onDelete { categories.remove(atOffsets: $0) }
            }

            if showingAdd {
                Section("New Category") {
                    TextField("Name", text: $newName)
                    ColorPicker("Color", selection: $selectedColor)
                    Button("Create") {
                        let hex = selectedColor.toHex() ?? "#007AFF"
                        categories.append(EventCategory(name: newName, colorHex: hex, icon: "tag.fill"))
                        newName = ""
                        showingAdd = false
                    }
                    .disabled(newName.isEmpty)
                }
            } else {
                Button("Add Category") { showingAdd = true }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            EditButton()
        }
    }
}
