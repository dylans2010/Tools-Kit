import SwiftUI

struct TaskCategoryView: View {
    @StateObject private var manager = TasksManager.shared
    @State private var showingCreate = false
    @State private var editingCategory: TaskCategory? = nil
    @State private var newName = ""
    @State private var newColorHex = "#007AFF"

    private let presetColors: [String] = [
        "#007AFF", "#34C759", "#FF3B30",
        "#FF9500", "#AF52DE", "#FF2D55",
        "#5AC8FA", "#FFCC00"
    ]

    var body: some View {
        List {
            ForEach(manager.categories) { cat in
                HStack(spacing: 12) {
                    Image(systemName: "folder")
                    Text(cat.name)
                    Spacer()
                    let count = manager.tasks.filter { $0.categoryID == cat.id }.count
                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        editingCategory = cat
                        newName = cat.name
                        newColorHex = cat.colorHex
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
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
            ToolbarItem(placement: .primaryAction) {
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
                Section("Category Name") {
                    TextField("Name", text: $newName)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(presetColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .accentColor)
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if isEdit { editingCategory = nil }
                        else { showingCreate = false }
                    }
                }
            }
        }
    }
}
