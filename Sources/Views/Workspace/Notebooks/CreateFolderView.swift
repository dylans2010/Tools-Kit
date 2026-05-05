import SwiftUI

struct CreateFolderView: View {
    let notebookID: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared
    @State private var name = ""
    @State private var selectedTemplate: FolderTemplate?

    enum FolderTemplate: String, CaseIterable, Identifiable {
        case project = "Project Workspace"
        case meeting = "Meeting Notes"
        case research = "Research Hub"
        case planning = "Product Planning"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .project: return "briefcase.fill"
            case .meeting: return "video.fill"
            case .research: return "lightbulb.fill"
            case .planning: return "calendar.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Folder Name") {
                    TextField("Enter Folder Name", text: $name)
                }

                Section("Templates") {
                    ForEach(FolderTemplate.allCases) { template in
                        Button(action: { selectedTemplate = template; name = template.rawValue }) {
                            HStack {
                                Label(template.rawValue, systemImage: template.icon)
                                Spacer()
                                if selectedTemplate == template {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let folderName = n.isEmpty ? "New Folder" : n
                        let folderID = UUID()

                        manager.addFolder(to: notebookID, name: folderName)

                        // Apply template if selected
                        if let template = selectedTemplate {
                            applyTemplate(template, to: folderID)
                        }

                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func applyTemplate(_ template: FolderTemplate, to folderName: String) {
        guard let notebook = manager.notebooks.first(where: { $0.id == notebookID }),
              let folder = notebook.folders.first(where: { $0.name == folderName }) else { return }

        let folderID = folder.id

        switch template {
        case .project:
            manager.addPage(to: folderID, in: notebookID, title: "Project Overview")
            manager.addPage(to: folderID, in: notebookID, title: "Milestones")
        case .meeting:
            manager.addPage(to: folderID, in: notebookID, title: "Agenda")
            manager.addPage(to: folderID, in: notebookID, title: "Action Items")
        case .research:
            manager.addPage(to: folderID, in: notebookID, title: "Bibliography")
            manager.addPage(to: folderID, in: notebookID, title: "Notes")
        case .planning:
            manager.addPage(to: folderID, in: notebookID, title: "Roadmap")
            manager.addPage(to: folderID, in: notebookID, title: "Requirements")
        }
    }
}
