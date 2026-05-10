import SwiftUI

struct EditingHomeView: View {
    @StateObject private var manager = EditingManager.shared
    @State private var showingCreateProject = false

    var body: some View {
        List {
            Section {
                if manager.projects.isEmpty {
                    Text("No projects yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(manager.projects) { project in
                        NavigationLink(destination: FullEditorView(projectID: project.id)) {
                            HStack {
                                Image(systemName: "photo")
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)

                                VStack(alignment: .leading) {
                                    Text(project.name)
                                        .font(.headline)
                                    Text("Last edited: \(project.updatedAt, style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Recent Projects")
            }

            Section(header: Text("Professional Suite")) {
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
                Text("Workflow")
            }
        }
        .navigationTitle("Media Editing")
        .toolbar {
            Button(action: { showingCreateProject = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView()
        }
    }
}

struct CreateProjectView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedCanvasPreset: CanvasPreset = .hd1080
    @State private var showingPhotoPicker = false
    @State private var showingVideoPicker = false
    @State private var showingFilePicker = false
    @State private var importedAssetNames: [String] = []

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
                        showingPhotoPicker = true
                    } label: {
                        Label("Import Photos", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        showingVideoPicker = true
                    } label: {
                        Label("Import Videos", systemImage: "video.badge.plus")
                    }

                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Import Files", systemImage: "doc.badge.plus")
                    }

                    if !importedAssetNames.isEmpty {
                        ForEach(importedAssetNames, id: \.self) { asset in
                            Label(asset, systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Import Media", systemImage: "square.and.arrow.down")
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let project = EditingManager.shared.createProject(
                            name: name,
                            canvasSize: selectedCanvasPreset.size
                        )
                        for assetName in importedAssetNames {
                            let layer = EditingLayer(
                                id: UUID(),
                                name: assetName,
                                type: assetName.hasSuffix(".mp4") || assetName.hasSuffix(".mov") ? .video : .image,
                                position: CGPoint(
                                    x: selectedCanvasPreset.size.width / 2,
                                    y: selectedCanvasPreset.size.height / 2
                                ),
                                scale: 1.0,
                                rotation: 0
                            )
                            var updatedProject = project
                            updatedProject.layers.append(layer)
                            EditingManager.shared.saveProject(updatedProject)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                MediaImportPlaceholderView(mediaType: "Photos") { names in
                    importedAssetNames.append(contentsOf: names)
                }
            }
            .sheet(isPresented: $showingVideoPicker) {
                MediaImportPlaceholderView(mediaType: "Videos") { names in
                    importedAssetNames.append(contentsOf: names)
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                MediaImportPlaceholderView(mediaType: "Files") { names in
                    importedAssetNames.append(contentsOf: names)
                }
            }
        }
    }
}

struct MediaImportPlaceholderView: View {
    let mediaType: String
    let onImport: ([String]) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: mediaType == "Videos" ? "video" : mediaType == "Photos" ? "photo" : "doc")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Import \(mediaType)")
                    .font(.title2.bold())

                Text("Select \(mediaType.lowercased()) from your device to add to the project.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    let sampleName = "Sample \(mediaType.dropLast()).\(mediaType == "Videos" ? "mp4" : mediaType == "Photos" ? "jpg" : "pdf")"
                    onImport([sampleName])
                    dismiss()
                } label: {
                    Label("Select from Library", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .navigationTitle("Import \(mediaType)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
