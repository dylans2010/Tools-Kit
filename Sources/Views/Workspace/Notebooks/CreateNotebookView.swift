import SwiftUI

struct CreateNotebookView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared
    @State private var name = ""
    @State private var selectedIcon = "book.closed"
    @State private var selectedColor = "#4F46E5"

    private let symbols = ["book.closed", "pencil", "graduationcap", "lightbulb", "brain", "doc.text", "folder", "archivebox", "calendar", "clock", "tag", "bookmark", "star", "heart", "globe", "house", "person", "envelope", "paperplane", "cart", "creditcard", "camera", "photo", "music.note", "video"]

    private let colors = ["#4F46E5", "#EF4444", "#F59E0B", "#10B981", "#3B82F6", "#8B5CF6", "#EC4899", "#6B7280"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Notebook Details") {
                    TextField("Enter Notebook Name", text: $name)
                }

                Section("Icon") {
                    NavigationLink(destination: SFSymbolPicker(selectedIcon: $selectedIcon)) {
                        HStack {
                            Text("Select Icon")
                            Spacer()
                            Image(systemName: selectedIcon)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .onTapGesture { selectedColor = color }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Notebook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        var nb = manager.createNotebook(name: n.isEmpty ? "Untitled Notebook" : n)
                        nb.iconName = selectedIcon
                        nb.colorHex = selectedColor
                        manager.updateNotebook(nb)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }
}
