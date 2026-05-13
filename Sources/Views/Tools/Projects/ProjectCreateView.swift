import SwiftUI

struct ProjectCreateView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (Project) -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColorHex = "007AFF"

    let icons = ["folder.fill", "doc.fill", "star.fill", "lightbulb.fill",
                 "chart.bar.fill", "briefcase.fill", "hammer.fill", "wrench.fill",
                 "paintbrush.fill", "globe", "lock.fill", "bell.fill",
                 "heart.fill", "bookmark.fill", "flag.fill", "trophy.fill"]

    let colors: [(String, String)] = [
        ("007AFF", "Blue"), ("34C759", "Green"), ("FF9500", "Orange"),
        ("FF2D55", "Red"), ("AF52DE", "Purple"), ("5AC8FA", "Light Blue"),
        ("FF6B6B", "Coral"), ("4ECDC4", "Teal"), ("FFE66D", "Yellow"),
        ("A8E6CF", "Mint")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $name)
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Description (optional)")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                } header: {
                    Text("Project Details")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .frame(width: 36, height: 36)
                                    .background(selectedIcon == icon ? Color(hex: selectedColorHex)))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Icon")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 10) {
                        ForEach(colors, id: \.0) { hex, _ in
                            Button {
                                selectedColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 2 : 0)
                                            .padding(2)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Color")
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let project = Project(
                            name: name,
                            description: description,
                            iconName: selectedIcon,
                            colorHex: selectedColorHex
                        )
                        onCreate(project)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
