import SwiftUI
import UniformTypeIdentifiers

struct FileManagementView: View {
    @StateObject private var backend = FileManagementBackend()
    @State private var showingImporter = false
    @State private var showingCreateFolder = false
    @State private var showingCreateFile = false
    @State private var showingTemplates = false

    var body: some View {
        ToolDetailView(tool: FileManagementTool()) {
            VStack(spacing: 16) {
                FileManagementStatsSectionView(backend: backend)
                FileManagementActionsSectionView(
                    backend: backend,
                    showingImporter: $showingImporter,
                    showingCreateFolder: $showingCreateFolder,
                    showingCreateFile: $showingCreateFile,
                    showingTemplates: $showingTemplates
                )
                FileManagementWorkspaceSectionView(backend: backend)

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
        .sheet(isPresented: $showingCreateFolder) {
            FileManagementCreateFolderSectionView(backend: backend) {
                showingCreateFolder = false
            }
        }
        .sheet(isPresented: $showingCreateFile) {
            FileManagementCreateFileSectionView(backend: backend) {
                showingCreateFile = false
            }
        }
        .sheet(isPresented: $showingTemplates) {
            FileManagementTemplateSectionView(backend: backend) {
                showingTemplates = false
            }
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

