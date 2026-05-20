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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(symbols, id: \.self) { symbol in
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == symbol ? Color.accentColor : Color.secondary.opacity(0.1))
                                    .foregroundColor(selectedIcon == symbol ? .white : .primary)
                                    .cornerRadius(8)
                                    .onTapGesture { selectedIcon = symbol }
                            }
                        }
                        .padding(.vertical, 4)
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
