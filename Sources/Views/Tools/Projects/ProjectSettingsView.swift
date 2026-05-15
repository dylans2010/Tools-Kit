import SwiftUI

struct ProjectSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ProjectsManager.shared
    @State private var project: Project
    @State private var showDeleteConfirm = false
    @State private var newTag = ""

    init(project: Project) {
        _project = State(initialValue: project)
    }

    let icons = ["folder.fill", "doc.fill", "star.fill", "lightbulb.fill",
                 "chart.bar.fill", "briefcase.fill", "hammer.fill", "wrench.fill",
                 "paintbrush.fill", "globe", "lock.fill", "bell.fill"]

    let colors: [(String, String)] = [
        ("007AFF", "Blue"), ("34C759", "Green"), ("FF9500", "Orange"),
        ("FF2D55", "Red"), ("AF52DE", "Purple"), ("5AC8FA", "Light Blue"),
        ("FF6B6B", "Coral"), ("4ECDC4", "Teal")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $project.name)
                    TextEditor(text: $project.description)
                        .frame(minHeight: 60)
                    Picker("Status", selection: $project.status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                } header: {
                    Text("General")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                project.iconName = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 18))
                                    .frame(width: 32, height: 32)
                                    .background(project.iconName == icon ? (Color(hex: project.colorHex)) : Color(uiColor: .secondarySystemGroupedBackground))
                                    .foregroundColor(project.iconName == icon ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                } header: {
                    Text("Icon")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(colors, id: \.0) { hex, _ in
                            Button {
                                project.colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        Circle().stroke(Color.primary, lineWidth: project.colorHex == hex ? 2 : 0).padding(2)
                                    )
                            }
                        }
                    }
                } header: {
                    Text("Color")
                }

                Section {
                    Toggle("Public Project", isOn: $project.settings.isPublic)
                } header: {
                    Text("Privacy")
                }

                Section {
                    Toggle("Allow File Uploads", isOn: $project.settings.allowFileUploads)
                    Toggle("Allow Annotations", isOn: $project.settings.allowAnnotations)
                } header: {
                    Text("Permissions")
                }

                Section {
                    Picker("Default Task Priority", selection: $project.settings.defaultTaskPriority) {
                        ForEach(ProjectTask.TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                } header: {
                    Text("Defaults")
                }

                Section {
                    ForEach(project.settings.tags, id: \.self) { tag in
                        Text(tag)
                    }
                    .onDelete { indexSet in
                        project.settings.tags.remove(atOffsets: indexSet)
                    }
                    HStack {
                        TextField("Add tag...", text: $newTag)
                        Button("Add") {
                            let tag = newTag.trimmingCharacters(in: .whitespaces)
                            guard !tag.isEmpty else { return }
                            project.settings.tags.append(tag)
                            newTag = ""
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Tags")
                }

                Section {
                    Toggle("Enable Notifications", isOn: $project.settings.notificationsEnabled)
                } header: {
                    Text("Notifications")
                }

                Section {
                    Button("Delete Project", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Project Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        manager.updateProject(project)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Delete Project", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    manager.deleteProject(id: project.id)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete the project and all its data.")
            }
        }
    }
}
