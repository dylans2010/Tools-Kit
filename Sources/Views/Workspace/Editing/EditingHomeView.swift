import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Imported Media Item

struct ImportedMediaItem: Identifiable {
    let id = UUID()
    let name: String
    let type: MediaImportType
    let fileSize: Int64
    let thumbnailSystemName: String
    let resourceIdentifier: String

    enum MediaImportType: String {
        case photo, video, document, audio

        var layerType: LayerType {
            switch self {
            case .photo: return .image
            case .video: return .video
            case .document: return .image
            case .audio: return .video
            }
        }
    }
}

// MARK: - Editing Mode

enum EditingEntryMode: String, Identifiable {
    case quickEdit = "Quick Edit"
    case fullEditor = "Full Editor"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .quickEdit: return "bolt.fill"
        case .fullEditor: return "slider.horizontal.below.square.and.square.filled"
        }
    }

    var subtitle: String {
        switch self {
        case .quickEdit: return "Filters, crop, and fast adjustments"
        case .fullEditor: return "Layers, tools, and full control"
        }
    }

    var gradient: [Color] {
        switch self {
        case .quickEdit: return [.orange, .pink]
        case .fullEditor: return [.blue, .purple]
        }
    }
}

// MARK: - EditingHomeView

struct EditingHomeView: View {
    @StateObject private var manager = EditingManager.shared
    @State private var showingImporter = false
    @State private var showingCreateProject = false
    @State private var pendingMode: EditingEntryMode = .fullEditor
    @State private var navigateToQuickEdit: EditingProject?
    @State private var navigateToFullEditor: EditingProject?

    private let projectColumns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                modeEntryCards
                recentProjectsSection
                workflowSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Media Editing")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingCreateProject = true
                    } label: {
                        Label("New Project", systemImage: "plus.rectangle.on.folder")
                    }
                    Button {
                        pendingMode = .fullEditor
                        showingImporter = true
                    } label: {
                        Label("Import Media", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView()
        }
        .sheet(isPresented: $showingImporter) {
            NavigationStack {
                FileImporterView(
                    allowedContentTypes: [.image, .png, .jpeg, .heic, .movie, .mpeg4Movie, .quickTimeMovie],
                    allowsMultipleSelection: true
                ) { urls in
                    handleImportedURLs(urls)
                }
                .navigationTitle("Import Media")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingImporter = false }
                    }
                }
            }
        }
        .navigationDestination(item: $navigateToQuickEdit) { project in
            FullEditorView(projectID: project.id, initialQuickEdit: true)
        }
        .navigationDestination(item: $navigateToFullEditor) { project in
            FullEditorView(projectID: project.id, initialQuickEdit: false)
        }
    }

    // MARK: - Mode Entry Cards

    private var modeEntryCards: some View {
        HStack(spacing: 16) {
            ForEach([EditingEntryMode.quickEdit, .fullEditor]) { mode in
                Button {
                    pendingMode = mode
                    showingImporter = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                        Text(mode.rawValue)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(mode.subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 12)
                    .background(
                        LinearGradient(
                            colors: mode.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Recent Projects

    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Projects", systemImage: "clock.arrow.circlepath")
                    .font(.title3.bold())
                Spacer()
                if !manager.projects.isEmpty {
                    Button("New Project") {
                        showingCreateProject = true
                    }
                    .font(.subheadline)
                }
            }

            if manager.projects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No Projects Yet")
                        .font(.headline)
                    Text("Import media or create a new project to get started.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVGrid(columns: projectColumns, spacing: 16) {
                    ForEach(manager.projects) { project in
                        NavigationLink(destination: FullEditorView(projectID: project.id)) {
                            projectCard(project)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                manager.deleteProject(id: project.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private func projectCard(_ project: EditingProject) -> some View {
        let hasVideo = project.layers.contains { $0.type == .video }
        let hasImage = project.layers.contains { $0.type == .image }

        return VStack(alignment: .leading, spacing: 8) {
            ZStack {
                LinearGradient(
                    colors: hasVideo ? [.purple.opacity(0.3), .blue.opacity(0.3)]
                            : hasImage ? [.orange.opacity(0.3), .pink.opacity(0.3)]
                            : [Color(.tertiarySystemFill), Color(.quaternarySystemFill)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: hasVideo ? "video.fill" : hasImage ? "photo.fill" : "doc.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Label("\(project.layers.count)", systemImage: "square.3.layers.3d")
                    Text("·")
                    Text("\(Int(project.canvasSize.width))×\(Int(project.canvasSize.height))")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                Text(project.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Workflow Section

    private var workflowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Workspace", systemImage: "gearshape.2")
                .font(.title3.bold())

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                NavigationLink(destination: ProfessionalToolsDashboard()) {
                    workflowTile(title: "Pro Tools", icon: "slider.horizontal.3", tint: .indigo)
                }
                NavigationLink(destination: AIEditControlsView()) {
                    workflowTile(title: "AI Assistant", icon: "sparkles", tint: .purple)
                }
                NavigationLink(destination: AssetManagerView()) {
                    workflowTile(title: "Assets", icon: "folder.fill", tint: .orange)
                }
                NavigationLink(destination: ExportQueueView()) {
                    workflowTile(title: "Export Queue", icon: "square.and.arrow.up.fill", tint: .green)
                }
                NavigationLink(destination: BatchProcessingView(projects: manager.projects)) {
                    workflowTile(title: "Batch Process", icon: "square.stack.3d.down.right.fill", tint: .teal)
                }
            }
        }
    }

    private func workflowTile(title: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Import Handling

    private func handleImportedURLs(_ urls: [URL]) {
        showingImporter = false
        guard !urls.isEmpty else { return }

        let project = manager.createProject(
            name: "Project \(Date().formatted(date: .abbreviated, time: .shortened))",
            canvasSize: CGSize(width: 1920, height: 1080)
        )
        var updatedProject = project
        for url in urls {
            let ext = url.pathExtension.lowercased()
            let layerType: LayerType
            switch ext {
            case "jpg", "jpeg", "png", "heic", "heif", "tiff", "bmp", "gif", "webp":
                layerType = .image
            case "mp4", "mov", "m4v":
                layerType = .video
            default:
                layerType = .image
            }
            let layer = EditingLayer(
                id: UUID(),
                name: url.lastPathComponent,
                type: layerType,
                position: CGPoint(x: 960, y: 540),
                scale: 1.0,
                rotation: 0,
                resourceID: url.absoluteString
            )
            updatedProject.layers.append(layer)
        }
        manager.saveProject(updatedProject)

        switch pendingMode {
        case .quickEdit:
            navigateToQuickEdit = updatedProject
        case .fullEditor:
            navigateToFullEditor = updatedProject
        }
    }
}

// MARK: - Hashable conformance for navigation

extension EditingProject: Hashable {
    static func == (lhs: EditingProject, rhs: EditingProject) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - CreateProjectView

struct CreateProjectView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedCanvasPreset: CanvasPreset = .hd1080
    @State private var showingFilePicker = false
    @State private var importedItems: [ImportedMediaItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $name)
                } header: {
                    Label("Details", systemImage: "doc.text")
                }

                Section {
                    Picker(selection: $selectedCanvasPreset) {
                        ForEach(CanvasPreset.allCases, id: \.name) { preset in
                            Text(preset.name).tag(preset)
                        }
                    } label: {
                        Label("Canvas Size", systemImage: "rectangle.dashed")
                    }
                } header: {
                    Label("Canvas", systemImage: "aspectratio")
                }

                Section {
                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Import from Files", systemImage: "doc.badge.plus")
                    }

                    if !importedItems.isEmpty {
                        ForEach(importedItems) { item in
                            HStack(spacing: 10) {
                                Image(systemName: item.thumbnailSystemName)
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline)
                                    Text(item.type.rawValue.capitalized)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .onDelete { offsets in
                            importedItems.remove(atOffsets: offsets)
                        }

                        Button(role: .destructive) {
                            importedItems.removeAll()
                        } label: {
                            Label("Clear All Imports", systemImage: "trash")
                        }
                    }
                } header: {
                    Label("Import Media", systemImage: "square.and.arrow.down")
                } footer: {
                    if !importedItems.isEmpty {
                        Text("\(importedItems.count) item(s) ready to import")
                    }
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                FileImporterView(
                    allowedContentTypes: [.image, .png, .jpeg, .heic, .movie, .mpeg4Movie, .quickTimeMovie],
                    allowsMultipleSelection: true
                ) { urls in
                    for url in urls {
                        let item = mediaItemFromURL(url)
                        importedItems.append(item)
                    }
                    showingFilePicker = false
                }
            }
        }
    }

    private func createProject() {
        let project = EditingManager.shared.createProject(
            name: name,
            canvasSize: selectedCanvasPreset.size
        )
        var updatedProject = project
        for item in importedItems {
            let layer = EditingLayer(
                id: UUID(),
                name: item.name,
                type: item.type.layerType,
                position: CGPoint(
                    x: selectedCanvasPreset.size.width / 2,
                    y: selectedCanvasPreset.size.height / 2
                ),
                scale: 1.0,
                rotation: 0,
                resourceID: item.resourceIdentifier
            )
            updatedProject.layers.append(layer)
        }
        EditingManager.shared.saveProject(updatedProject)
        dismiss()
    }

    private func mediaItemFromURL(_ url: URL) -> ImportedMediaItem {
        let ext = url.pathExtension.lowercased()
        let type: ImportedMediaItem.MediaImportType
        let icon: String
        switch ext {
        case "jpg", "jpeg", "png", "heic", "heif", "tiff", "bmp", "gif", "webp":
            type = .photo; icon = "photo.fill"
        case "mp4", "mov", "m4v", "avi", "mkv":
            type = .video; icon = "video.fill"
        case "mp3", "aac", "wav", "aiff", "m4a", "flac":
            type = .audio; icon = "waveform"
        default:
            type = .document; icon = "doc.fill"
        }
        return ImportedMediaItem(
            name: url.lastPathComponent,
            type: type,
            fileSize: (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0,
            thumbnailSystemName: icon,
            resourceIdentifier: url.absoluteString
        )
    }
}
