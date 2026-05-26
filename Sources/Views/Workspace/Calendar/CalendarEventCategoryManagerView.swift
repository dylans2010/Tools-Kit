import SwiftUI

struct CalendarEventCategoryManagerView: View {
    @State private var categories: [EventCategory] = [
        EventCategory(name: "Work", color: .blue, icon: "briefcase.fill"),
        EventCategory(name: "Personal", color: .green, icon: "person.fill"),
        EventCategory(name: "Health", color: .red, icon: "heart.fill"),
        EventCategory(name: "Education", color: .purple, icon: "book.fill")
    ]
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var selectedColor: Color = .blue

    struct EventCategory: Identifiable, Codable {
        let id = UUID()
        var name: String
        var color: Color
        var icon: String
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
                        categories.append(EventCategory(name: newName, color: selectedColor, icon: "tag.fill"))
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
