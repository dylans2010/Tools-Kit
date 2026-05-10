import SwiftUI

struct CreateCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ArticlesManager.shared

    @State private var name = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "3B82F6"

    private let icons = [
        "folder", "book", "star", "heart", "bookmark",
        "tag", "lightbulb", "globe", "brain.head.profile", "graduationcap",
        "newspaper", "doc.text", "magnifyingglass", "pin", "flag"
    ]

    private let colors = [
        "3B82F6", "EF4444", "10B981", "F59E0B", "8B5CF6",
        "EC4899", "06B6D4", "F97316", "6366F1", "14B8A6"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Collection Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .accentColor)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(Color.primary, lineWidth: selectedColor == hex ? 2.5 : 0)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        manager.createCollection(name: n.isEmpty ? "Untitled" : n, icon: selectedIcon, colorHex: selectedColor)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.large])
    }
}
