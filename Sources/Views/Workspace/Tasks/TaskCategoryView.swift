import SwiftUI

struct TaskCategoryView: View {
    @ObservedObject var manager: TasksManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreate = false
    @State private var editingCategory: TaskCategory?
    @State private var newName = ""
    @State private var newColorHex = "3B82F6"

    private let colorOptions = [
        ("Blue", "3B82F6"), ("Green", "22C55E"), ("Purple", "A855F7"),
        ("Orange", "F97316"), ("Red", "EF4444"), ("Pink", "EC4899"),
        ("Teal", "14B8A6"), ("Yellow", "EAB308")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(manager.categories) { cat in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: cat.colorHex) ?? .blue)
                            .frame(width: 14, height: 14)
                        Text(cat.name)
                        Spacer()
                        Text("\(manager.tasks.filter { $0.categoryID == cat.id }.count) tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            manager.deleteCategory(cat)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingCategory = cat
                            newName = cat.name
                            newColorHex = cat.colorHex
                            showingCreate = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingCreate, onDismiss: { editingCategory = nil; newName = ""; newColorHex = "3B82F6" }) {
                categoryForm
            }
        }
    }

    private var categoryForm: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Work", text: $newName)
                }
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(colorOptions, id: \.1) { _, hex in
                                Button { newColorHex = hex } label: {
                                    Circle()
                                        .fill(Color(hex: hex) ?? .blue)
                                        .frame(width: 32, height: 32)
                                        .overlay(Circle().stroke(Color.primary, lineWidth: newColorHex == hex ? 3 : 0))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(editingCategory == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { showingCreate = false } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editingCategory == nil ? "Create" : "Save") { saveCategory() }
                        .bold()
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveCategory() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        if var existing = editingCategory {
            existing.name = name
            existing.colorHex = newColorHex
            manager.updateCategory(existing)
        } else {
            manager.addCategory(TaskCategory(name: name, colorHex: newColorHex))
        }
        showingCreate = false
    }
}
