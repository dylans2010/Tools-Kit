import SwiftUI
import UniformTypeIdentifiers

struct FileManagementView: View {
    @StateObject private var backend = FileManagementBackend()
    @State private var newFileName = ""
    @State private var newFolderName = ""
    @State private var selectedType: ManagedFileType = .text
    @State private var selectedTemplate: FileTemplate = .html
    @State private var showingImporter = false

    var body: some View {
        ToolDetailView(tool: FileManagementTool()) {
            VStack(spacing: 16) {
                FileStatsView(backend: backend)

                ToolInputSection("Create Folder") {
                    HStack {
                        TextField("Folder name", text: $newFolderName)
                            .textFieldStyle(.roundedBorder)
                        Button("Create") {
                            backend.createFolder(name: newFolderName)
                            newFolderName = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }

                ToolInputSection("Create File") {
                    VStack(spacing: 10) {
                        TextField("File name", text: $newFileName)
                            .textFieldStyle(.roundedBorder)
                        Picker("Type", selection: $selectedType) {
                            ForEach(FileManagementFeatures.supportedCreationTypes) { type in
                                Text(".\(type.rawValue)").tag(type)
                            }
                        }
                        Button("Create File") {
                            backend.createFile(name: newFileName, type: selectedType)
                            newFileName = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }

                ToolInputSection("Templates") {
                    HStack {
                        Picker("Template", selection: $selectedTemplate) {
                            ForEach(FileManagementFeatures.supportedTemplates) { template in
                                Text(template.rawValue).tag(template)
                            }
                        }
                        Button("Create") {
                            backend.createFromTemplate(selectedTemplate)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }

                ToolInputSection("Workspace") {
                    VStack(spacing: 0) {
                        ForEach(backend.items) { item in
                            HStack {
                                Image(systemName: item.isDirectory ? "folder.fill" : "doc.text")
                                    .foregroundColor(item.isDirectory ? .orange : .blue)
                                VStack(alignment: .leading) {
                                    Text(item.url.lastPathComponent)
                                    Text(item.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if !item.isDirectory {
                                    ShareLink(item: item.url) {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                }
                                Button {
                                    backend.selectedItem = item
                                } label: {
                                    Image(systemName: backend.selectedItem?.id == item.id ? "checkmark.circle.fill" : "circle")
                                }
                                Button(role: .destructive) {
                                    backend.delete(item)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .padding()
                            if item.id != backend.items.last?.id { Divider() }
                        }
                    }
                }

                HStack {
                    Button("Import Files") {
                        showingImporter = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        Task { await backend.summarizeSelectedFile() }
                    } label: {
                        if backend.isSummarizing {
                            ProgressView()
                        } else {
                            Text("AI Summary")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(backend.selectedItem == nil)
                }

                if !backend.aiSummary.isEmpty {
                    ToolOutputView("Inspector Summary", value: backend.aiSummary)
                }
            }
        }
        .sheet(isPresented: $showingImporter) {
            FileImporterRepresentableView(
                allowedContentTypes: [UTType.item],
                allowsMultipleSelection: true
            ) { urls in
                backend.importFiles(urls: urls)
                showingImporter = false
            }
        }
    }
}

struct FileStatsView: View {
    @ObservedObject var backend: FileManagementBackend

    var body: some View {
        ToolInputSection("Stats") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Items: \(backend.totalCount)")
                Text("Files: \(backend.totalFiles)")
                Text("Folders: \(backend.totalFolders)")
                Text("Storage: \(ByteCountFormatter.string(fromByteCount: backend.totalBytes, countStyle: .file))")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FileManagementTool: Tool {
    let name = "File Management"
    let icon = "folder.badge.gearshape"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Create, organize, inspect, import/export files and folders with AI insights"
    let requiresAPI = true

    var view: AnyView { AnyView(FileManagementView()) }
}
