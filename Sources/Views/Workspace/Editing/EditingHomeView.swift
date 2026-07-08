import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Imported Media Item

struct ImportedMediaItem: Identifiable {
    let id = UUID()
    let name: String
    let type: MediaImportType
    let fileSize: Int64
    let thumbnailSystemName: String
    let resourceIdentifier: String
    var thumbnailImage: UIImage?

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

// MARK: - UIKit Image Loader

final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false

    func loadImage(from url: URL) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard url.startAccessingSecurityScopedResource() else {
                DispatchQueue.main.async { self?.isLoading = false }
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            if let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image = uiImage
                    self?.isLoading = false
                }
            } else {
                DispatchQueue.main.async { self?.isLoading = false }
            }
        }
    }

    func loadImage(from data: Data) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let uiImage = UIImage(data: data)
            DispatchQueue.main.async {
                self?.image = uiImage
                self?.isLoading = false
            }
        }
    }
}

// MARK: - UIKit Image View Wrapper

struct UIKitImageView: UIViewRepresentable {
    let image: UIImage
    var contentMode: UIView.ContentMode = .scaleAspectFit

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
        uiView.contentMode = contentMode
    }
}

// MARK: - UIKit Photo Picker Bridge

struct PhotoPickerBridge: UIViewControllerRepresentable {
    let onPicked: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .any(of: [.images, .livePhotos])
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPicked: ([UIImage]) -> Void
        init(onPicked: @escaping ([UIImage]) -> Void) { self.onPicked = onPicked }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            var images: [UIImage] = []
            let group = DispatchGroup()
            for result in results {
                guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) { [weak self] in
                self?.onPicked(images)
            }
        }
    }
}

// MARK: - UIKit Camera Capture

struct CameraCaptureView: UIViewControllerRepresentable {
    let onCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCaptured: onCaptured) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCaptured: (UIImage) -> Void
        init(onCaptured: @escaping (UIImage) -> Void) { self.onCaptured = onCaptured }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                onCaptured(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Image Thumbnail Generator

struct ThumbnailGenerator {
    static func generateThumbnail(from url: URL, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url),
              let original = UIImage(data: data) else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            original.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    static func generateThumbnail(from image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
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
    @State private var showingPhotosPicker = false
    @State private var showingCamera = false
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
                quickImportSection
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
                        Label("Import from Files", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        showingPhotosPicker = true
                    } label: {
                        Label("Import from Photos", systemImage: "photo.on.rectangle")
                    }
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                        }
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
        .sheet(isPresented: $showingPhotosPicker) {
            PhotoPickerBridge { images in
                handlePickedImages(images)
                showingPhotosPicker = false
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCaptureView { image in
                handleCapturedImage(image)
                showingCamera = false
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

    // MARK: - Quick Import Section

    private var quickImportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Import", systemImage: "square.and.arrow.down")
                .font(.title3.bold())

            HStack(spacing: 12) {
                quickImportTile(title: "Photos", icon: "photo.on.rectangle", tint: .blue) {
                    showingPhotosPicker = true
                }
                quickImportTile(title: "Files", icon: "folder", tint: .orange) {
                    showingImporter = true
                }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    quickImportTile(title: "Camera", icon: "camera", tint: .green) {
                        showingCamera = true
                    }
                }
                quickImportTile(title: "Clipboard", icon: "clipboard", tint: .purple) {
                    importFromClipboard()
                }
            }
        }
    }

    private func quickImportTile(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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
                            Button {
                                navigateToQuickEdit = project
                            } label: {
                                Label("Quick Edit", systemImage: "bolt.fill")
                            }
                            Button {
                                navigateToFullEditor = project
                            } label: {
                                Label("Full Editor", systemImage: "slider.horizontal.below.square.and.square.filled")
                            }
                            Divider()
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

    private func handlePickedImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }

        let project = manager.createProject(
            name: "Photos \(Date().formatted(date: .abbreviated, time: .shortened))",
            canvasSize: CGSize(width: 1920, height: 1080)
        )
        var updatedProject = project
        for (idx, image) in images.enumerated() {
            let fileName = "photo_\(idx + 1).jpg"
            if let data = image.jpegData(compressionQuality: 0.9) {
                let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = docURL.appendingPathComponent("\(project.id.uuidString)_\(fileName)")
                try? data.write(to: fileURL)

                let layer = EditingLayer(
                    id: UUID(),
                    name: fileName,
                    type: .image,
                    position: CGPoint(x: 960, y: 540),
                    scale: 1.0,
                    rotation: 0,
                    resourceID: fileURL.absoluteString
                )
                updatedProject.layers.append(layer)
            }
        }
        manager.saveProject(updatedProject)
        navigateToFullEditor = updatedProject
    }

    private func handleCapturedImage(_ image: UIImage) {
        let project = manager.createProject(
            name: "Capture \(Date().formatted(date: .abbreviated, time: .shortened))",
            canvasSize: CGSize(width: image.size.width, height: image.size.height)
        )
        var updatedProject = project
        if let data = image.jpegData(compressionQuality: 0.9) {
            let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = docURL.appendingPathComponent("\(project.id.uuidString)_capture.jpg")
            try? data.write(to: fileURL)

            let layer = EditingLayer(
                id: UUID(),
                name: "Captured Photo",
                type: .image,
                position: CGPoint(x: image.size.width / 2, y: image.size.height / 2),
                scale: 1.0,
                rotation: 0,
                resourceID: fileURL.absoluteString
            )
            updatedProject.layers.append(layer)
        }
        manager.saveProject(updatedProject)
        navigateToFullEditor = updatedProject
    }

    private func importFromClipboard() {
        guard let image = UIPasteboard.general.image else { return }
        handleCapturedImage(image)
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
    @State private var showingPhotosPicker = false
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

                    Button {
                        showingPhotosPicker = true
                    } label: {
                        Label("Import from Photos", systemImage: "photo.on.rectangle")
                    }

                    if !importedItems.isEmpty {
                        ForEach(importedItems) { item in
                            HStack(spacing: 10) {
                                if let thumbnail = item.thumbnailImage {
                                    UIKitImageView(image: thumbnail, contentMode: .scaleAspectFill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    Image(systemName: item.thumbnailSystemName)
                                        .foregroundStyle(.blue)
                                        .frame(width: 40, height: 40)
                                }
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
            .sheet(isPresented: $showingPhotosPicker) {
                PhotoPickerBridge { images in
                    for (idx, image) in images.enumerated() {
                        let thumbnail = ThumbnailGenerator.generateThumbnail(from: image)
                        var item = ImportedMediaItem(
                            name: "Photo \(importedItems.count + idx + 1).jpg",
                            type: .photo,
                            fileSize: Int64(image.jpegData(compressionQuality: 0.8)?.count ?? 0),
                            thumbnailSystemName: "photo.fill",
                            resourceIdentifier: UUID().uuidString
                        )
                        item.thumbnailImage = thumbnail
                        importedItems.append(item)
                    }
                    showingPhotosPicker = false
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

        let thumbnail = (type == .photo) ? ThumbnailGenerator.generateThumbnail(from: url) : nil

        var item = ImportedMediaItem(
            name: url.lastPathComponent,
            type: type,
            fileSize: (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0,
            thumbnailSystemName: icon,
            resourceIdentifier: url.absoluteString
        )
        item.thumbnailImage = thumbnail
        return item
    }
}
