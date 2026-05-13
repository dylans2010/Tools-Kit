import SwiftUI
import PhotosUI

struct ProjectDetailsView: View {
    let project: Project
    @StateObject private var manager = ProjectsManager.shared
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showAddTask = false
    @State private var showAddAnnotation = false
    @State private var showAddCollaborator = false
    @State private var showFileImporter = false
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var newAnnotation = ""
    @State private var newCollaboratorName = ""
    @State private var newCollaboratorEmail = ""
    @State private var newCollaboratorRole: CollaboratorRole = .member

    var currentProject: Project {
        manager.projects.first(where: { $0.id == project.id }) ?? project
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            TabView(selection: $selectedTab) {
                overviewTab.tag(0)
                tasksTab.tag(1)
                filesTab.tag(2)
                annotationsTab.tag(3)
                teamTab.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(currentProject.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ProjectSettingsView(project: currentProject)
        }
        .sheet(isPresented: $showAddTask) {
            ProjectTaskDetailView(projectID: currentProject.id, task: nil)
        }
        .sheet(isPresented: $showFileImporter) {
            FileImporterRepresentableView(allowedContentTypes: [.data, .image, .pdf, .text], allowsMultipleSelection: false) { urls in
                handleImportedURLs(urls)
                showFileImporter = false
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item = item else { return }
            loadPhoto(from: item)
        }
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.0) { idx, tab in
                    Button {
                        withAnimation { selectedTab = idx }
                    } label: {
                        VStack(spacing: 4) {
                            Text(tab)
                                .font(.subheadline)
                                .fontWeight(selectedTab == idx ? .semibold : .regular)
                                .foregroundColor(selectedTab == idx ? .primary : .secondary)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)

                            Rectangle()
                                .fill(selectedTab == idx ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    let tabs = ["Overview", "Tasks", "Files", "Notes", "Team"]

    // MARK: - Overview
    private var overviewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: currentProject.colorHex))
                            .frame(width: 56, height: 56)
                        Image(systemName: currentProject.iconName)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentProject.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        StatusBadge(status: currentProject.status)
                    }
                    Spacer()
                }

                if !currentProject.description.isEmpty {
                    Text(currentProject.description)
                        .foregroundColor(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Tasks", value: "\(currentProject.tasks.count)", icon: "checkmark.circle", color: .blue)
                    StatCard(title: "Files", value: "\(currentProject.files.count)", icon: "doc", color: .orange)
                    StatCard(title: "Team", value: "\(currentProject.collaborators.count)", icon: "person.2", color: .green)
                }

                Text("Created \(currentProject.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    // MARK: - Tasks
    private var tasksTab: some View {
        VStack {
            List {
                ForEach(currentProject.tasks) { task in
                    TaskRowView(task: task) {
                        manager.toggleTaskStatus(taskID: task.id, in: currentProject.id)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            manager.deleteTask(id: task.id, from: currentProject.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                if currentProject.tasks.isEmpty {
                    ContentUnavailableLabel(title: "No Tasks", icon: "checkmark.circle", message: "Tap + to add your first task")
                }
            }
            .listStyle(.insetGrouped)

            Button {
                showAddTask = true
            } label: {
                Label("Add Task", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding()
            }
        }
    }

    // MARK: - Files
    private var filesTab: some View {
        VStack {
            if currentProject.files.isEmpty {
                Spacer()
                ContentUnavailableLabel(title: "No Files", icon: "doc", message: "Upload files to this project")
                Spacer()
            } else {
                List {
                    ForEach(currentProject.files) { file in
                        FileRowView(file: file)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    manager.deleteFile(id: file.id, from: currentProject.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Photo", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }

                Button {
                    showFileImporter = true
                } label: {
                    Label("File", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    // MARK: - Annotations
    private var annotationsTab: some View {
        VStack {
            List {
                ForEach(currentProject.annotations) { annotation in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(annotation.content)
                        HStack {
                            Text(annotation.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(annotation.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            manager.deleteAnnotation(id: annotation.id, from: currentProject.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                if currentProject.annotations.isEmpty {
                    ContentUnavailableLabel(title: "No Notes", icon: "note.text", message: "Add notes to keep track of important information")
                }
            }
            .listStyle(.insetGrouped)

            HStack {
                TextField("Add a note...", text: $newAnnotation, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
                Button {
                    guard !newAnnotation.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let ann = ProjectAnnotation(content: newAnnotation)
                    manager.addAnnotation(to: currentProject.id, annotation: ann)
                    newAnnotation = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Team
    private var teamTab: some View {
        VStack {
            List {
                ForEach(currentProject.collaborators) { collaborator in
                    CollaboratorRowView(collaborator: collaborator)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                manager.removeCollaborator(id: collaborator.id, from: currentProject.id)
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                        }
                }

                if currentProject.collaborators.isEmpty {
                    ContentUnavailableLabel(title: "No Team Members", icon: "person.2", message: "Invite collaborators to this project")
                }
            }
            .listStyle(.insetGrouped)

            Button {
                showAddCollaborator = true
            } label: {
                Label("Invite Member", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding()
            }
        }
        .sheet(isPresented: $showAddCollaborator) {
            addCollaboratorSheet
        }
    }

    private var addCollaboratorSheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newCollaboratorName)
                TextField("Email", text: $newCollaboratorEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                Picker("Role", selection: $newCollaboratorRole) {
                    ForEach(CollaboratorRole.allCases, id: \.self) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showAddCollaborator = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let collaborator = ProjectCollaborator(
                            name: newCollaboratorName,
                            email: newCollaboratorEmail,
                            role: newCollaboratorRole
                        )
                        manager.addCollaborator(to: currentProject.id, collaborator: collaborator)
                        newCollaboratorName = ""
                        newCollaboratorEmail = ""
                        newCollaboratorRole = .member
                        showAddCollaborator = false
                    }
                    .disabled(newCollaboratorName.isEmpty)
                }
            }
        }
    }

    // MARK: - File Handling
    private func handleImportedURLs(_ urls: [URL]) {
        guard let url = urls.first else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return }
        let mimeType = mimeTypeFor(ext: url.pathExtension)
        let file = ProjectFile(fileName: url.lastPathComponent, mimeType: mimeType, data: data)
        manager.addFile(to: currentProject.id, file: file)
    }

    private func loadPhoto(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                if case .success(let data) = result, let data = data {
                    let file = ProjectFile(fileName: "photo_\(Date().timeIntervalSince1970).jpg", mimeType: "image/jpeg", data: data)
                    manager.addFile(to: currentProject.id, file: file)
                }
                selectedPhotoItem = nil
            }
        }
    }

    private func mimeTypeFor(ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TaskRowView: View {
    let task: ProjectTask
    let onToggle: () -> Void

    var statusIcon: String {
        switch task.status {
        case .todo: return "circle"
        case .inProgress: return "circle.badge.clock"
        case .done: return "checkmark.circle.fill"
        }
    }

    var priorityColor: Color {
        switch task.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundColor(task.status == .done ? .green : .secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.status == .done)
                    .foregroundColor(task.status == .done ? .secondary : .primary)
                if let due = task.dueDate {
                    Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
        }
    }
}

struct FileRowView: View {
    let file: ProjectFile

    var icon: String {
        if file.mimeType.hasPrefix("image") { return "photo" }
        if file.mimeType == "application/pdf" { return "doc.richtext" }
        return "doc"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .lineLimit(1)
                Text("\(file.addedBy) · \(file.addedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: Int64(file.data.count), countStyle: .file))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CollaboratorRowView: View {
    let collaborator: ProjectCollaborator

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(collaborator.avatarInitials)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(collaborator.name)
                    .fontWeight(.medium)
                Text(collaborator.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(collaborator.role.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
    }
}

struct ContentUnavailableLabel: View {
    let title: String
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
