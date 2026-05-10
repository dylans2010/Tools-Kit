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

// MARK: - EditingHomeView

struct EditingHomeView: View {
    @StateObject private var manager = EditingManager.shared
    @State private var showingCreateProject = false
    @State private var showingQuickImport = false
    @State private var quickImportItems: [ImportedMediaItem] = []

    var body: some View {
        List {
            Section {
                if manager.projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects Yet",
                        systemImage: "film.stack",
                        description: Text("Tap + to create a new project or import media to get started.")
                    )
                } else {
                    ForEach(manager.projects) { project in
                        NavigationLink(destination: FullEditorView(projectID: project.id)) {
                            HStack(spacing: 12) {
                                projectThumbnail(for: project)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(project.name)
                                        .font(.headline)
                                    HStack(spacing: 8) {
                                        Label("\(project.layers.count)", systemImage: "square.3.layers.3d")
                                        Label("\(Int(project.canvasSize.width))×\(Int(project.canvasSize.height))", systemImage: "aspectratio")
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    Text("Last edited: \(project.updatedAt, style: .relative) ago")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { offsets in
                        for idx in offsets {
                            manager.deleteProject(id: manager.projects[idx].id)
                        }
                    }
                }
            } header: {
                Label("Recent Projects", systemImage: "clock.arrow.circlepath")
            }

            Section(header: Label("Professional Suite", systemImage: "star.fill")) {
                NavigationLink(destination: ProfessionalToolsDashboard()) {
                    Label("Pro Tools", systemImage: "slider.horizontal.3")
                }
                NavigationLink(destination: AIEditControlsView()) {
                    Label("AI Assistant", systemImage: "sparkles")
                }
            }

            Section {
                NavigationLink(destination: AssetManagerView()) {
                    Label("Asset Manager", systemImage: "folder.fill")
                }
                NavigationLink(destination: ExportQueueView()) {
                    Label("Export Queue", systemImage: "square.and.arrow.up.fill")
                }
                NavigationLink(destination: BatchProcessingView(projects: manager.projects)) {
                    Label("Batch Processing", systemImage: "square.stack.3d.down.right.fill")
                }
            } header: {
                Label("Workflow", systemImage: "gearshape.2")
            }
        }
        .navigationTitle("Media Editing")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showingCreateProject = true }) {
                        Label("New Project", systemImage: "plus.rectangle.on.folder")
                    }
                    Button(action: { showingQuickImport = true }) {
                        Label("Quick Import", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView()
        }
        .sheet(isPresented: $showingQuickImport) {
            NavigationStack {
                QuickImportView { items in
                    if !items.isEmpty {
                        let project = manager.createProject(
                            name: "Imported \(Date().formatted(date: .abbreviated, time: .shortened))",
                            canvasSize: CGSize(width: 1920, height: 1080)
                        )
                        var updatedProject = project
                        for item in items {
                            let layer = EditingLayer(
                                id: UUID(),
                                name: item.name,
                                type: item.type.layerType,
                                position: CGPoint(x: 960, y: 540),
                                scale: 1.0,
                                rotation: 0,
                                resourceID: item.resourceIdentifier
                            )
                            updatedProject.layers.append(layer)
                        }
                        manager.saveProject(updatedProject)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func projectThumbnail(for project: EditingProject) -> some View {
        let hasVideo = project.layers.contains { $0.type == .video }
        let hasImage = project.layers.contains { $0.type == .image }
        let icon = hasVideo ? "video.fill" : hasImage ? "photo.fill" : "doc.fill"

        Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(
                LinearGradient(
                    colors: hasVideo ? [.purple, .blue] : hasImage ? [.orange, .pink] : [.gray, .secondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 10)
            )
    }
}

// MARK: - CreateProjectView

struct CreateProjectView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedCanvasPreset: CanvasPreset = .hd1080
    @State private var showingPhotoPicker = false
    @State private var showingFilePicker = false
    @State private var importedItems: [ImportedMediaItem] = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

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
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: 20,
                        matching: .any(of: [.images, .videos])
                    ) {
                        Label("Import from Photos", systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: selectedPhotoItems) { _, newItems in
                        Task { await processPhotoPickerItems(newItems) }
                    }

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
                            selectedPhotoItems.removeAll()
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
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: supportedFileTypes,
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private var supportedFileTypes: [UTType] {
        [.image, .movie, .audio, .pdf, .png, .jpeg, .heic, .mpeg4Movie, .quickTimeMovie, .mp3, .aiff]
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

    @MainActor
    private func processPhotoPickerItems(_ items: [PhotosPickerItem]) async {
        for item in items {
            let mediaItem: ImportedMediaItem
            if let contentType = item.supportedContentTypes.first {
                let isVideo = contentType.conforms(to: .movie) || contentType.conforms(to: .video)
                let identifier = item.itemIdentifier ?? UUID().uuidString
                let name = isVideo ? "Video_\(identifier.prefix(8)).mov" : "Photo_\(identifier.prefix(8)).jpg"
                mediaItem = ImportedMediaItem(
                    name: name,
                    type: isVideo ? .video : .photo,
                    fileSize: 0,
                    thumbnailSystemName: isVideo ? "video.fill" : "photo.fill",
                    resourceIdentifier: identifier
                )
            } else {
                let identifier = item.itemIdentifier ?? UUID().uuidString
                mediaItem = ImportedMediaItem(
                    name: "Media_\(identifier.prefix(8))",
                    type: .photo,
                    fileSize: 0,
                    thumbnailSystemName: "photo.fill",
                    resourceIdentifier: identifier
                )
            }
            if !importedItems.contains(where: { $0.resourceIdentifier == mediaItem.resourceIdentifier }) {
                importedItems.append(mediaItem)
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let fileName = url.lastPathComponent
                let ext = url.pathExtension.lowercased()
                let type: ImportedMediaItem.MediaImportType
                let icon: String

                switch ext {
                case "jpg", "jpeg", "png", "heic", "heif", "tiff", "bmp", "gif", "webp":
                    type = .photo
                    icon = "photo.fill"
                case "mp4", "mov", "m4v", "avi", "mkv":
                    type = .video
                    icon = "video.fill"
                case "mp3", "aac", "wav", "aiff", "m4a", "flac":
                    type = .audio
                    icon = "waveform"
                default:
                    type = .document
                    icon = "doc.fill"
                }

                let item = ImportedMediaItem(
                    name: fileName,
                    type: type,
                    fileSize: (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0,
                    thumbnailSystemName: icon,
                    resourceIdentifier: url.absoluteString
                )
                importedItems.append(item)
            }
        case .failure:
            break
        }
    }
}

// MARK: - QuickImportView

struct QuickImportView: View {
    let onImport: ([ImportedMediaItem]) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var importedItems: [ImportedMediaItem] = []
    @State private var showingFilePicker = false

    var body: some View {
        List {
            Section {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 50,
                    matching: .any(of: [.images, .videos])
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Photos Library")
                                .font(.headline)
                            Text("Select photos and videos from your library")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onChange(of: selectedPhotoItems) { _, newItems in
                    Task { await processPickerItems(newItems) }
                }

                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .frame(width: 44, height: 44)
                            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Browse Files")
                                .font(.headline)
                            Text("Import images, videos, audio, and documents")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Label("Import Source", systemImage: "square.and.arrow.down")
            }

            if !importedItems.isEmpty {
                Section {
                    ForEach(importedItems) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.thumbnailSystemName)
                                .foregroundStyle(.blue)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
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
                } header: {
                    Label("Selected Media (\(importedItems.count))", systemImage: "photo.stack")
                }
            }
        }
        .navigationTitle("Quick Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Import") {
                    onImport(importedItems)
                    dismiss()
                }
                .disabled(importedItems.isEmpty)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image, .movie, .audio, .pdf],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                for url in urls {
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
                    importedItems.append(ImportedMediaItem(
                        name: url.lastPathComponent,
                        type: type,
                        fileSize: (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0,
                        thumbnailSystemName: icon,
                        resourceIdentifier: url.absoluteString
                    ))
                }
            }
        }
    }

    @MainActor
    private func processPickerItems(_ items: [PhotosPickerItem]) async {
        for item in items {
            let isVideo = item.supportedContentTypes.first.map {
                $0.conforms(to: .movie) || $0.conforms(to: .video)
            } ?? false
            let identifier = item.itemIdentifier ?? UUID().uuidString
            let name = isVideo ? "Video_\(identifier.prefix(8)).mov" : "Photo_\(identifier.prefix(8)).jpg"
            let mediaItem = ImportedMediaItem(
                name: name,
                type: isVideo ? .video : .photo,
                fileSize: 0,
                thumbnailSystemName: isVideo ? "video.fill" : "photo.fill",
                resourceIdentifier: identifier
            )
            if !importedItems.contains(where: { $0.resourceIdentifier == mediaItem.resourceIdentifier }) {
                importedItems.append(mediaItem)
            }
        }
    }
}
