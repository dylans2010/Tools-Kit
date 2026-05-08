import SwiftUI

struct TaskCategoryView: View {
    @StateObject private var manager = TasksManager.shared
    @State private var showingCreate = false
    @State private var editingCategory: TaskCategory? = nil
    @State private var newName = ""
    @State private var newColorHex = "#007AFF"

    private let presetColors: [(String, Color)] = [
        ("#007AFF", .blue), ("#34C759", .green), ("#FF3B30", .red),
        ("#FF9500", .orange), ("#AF52DE", .purple), ("#FF2D55", .pink),
        ("#5AC8FA", .cyan), ("#FFCC00", .yellow)
    ]

    var body: some View {
        List {
            ForEach(manager.categories) { cat in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: cat.colorHex) ?? .blue)
                        .frame(width: 14, height: 14)
                    Text(cat.name)
                    Spacer()
                    let count = manager.tasks.filter { $0.categoryID == cat.id }.count
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button {
                        editingCategory = cat
                        newName = cat.name
                        newColorHex = cat.colorHex
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        manager.deleteCategory(cat)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newName = ""
                    newColorHex = "#007AFF"
                    showingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            categoryFormSheet(isEdit: false)
        }
        .sheet(item: $editingCategory) { _ in
            categoryFormSheet(isEdit: true)
        }
    }

    private func categoryFormSheet(isEdit: Bool) -> some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $newName)
                } header: {
                    Text("Category Name")
                }
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(presetColors, id: \.0) { hex, color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(0.4), lineWidth: newColorHex == hex ? 2.5 : 0)
                                        .padding(2)
                                )
                                .onTapGesture { newColorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Color")
                }
                Section {
                    Button(action: {
                        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if isEdit, var cat = editingCategory {
                            cat.name = trimmed
                            cat.colorHex = newColorHex
                            manager.updateCategory(cat)
                            editingCategory = nil
                        } else {
                            manager.addCategory(TaskCategory(name: trimmed, colorHex: newColorHex))
                            showingCreate = false
                        }
                    }) {
                        Text(isEdit ? "Save" : "Create Category")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(isEdit ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if isEdit { editingCategory = nil }
                        else { showingCreate = false }
                    }
                }
            }
        }
    }
}
