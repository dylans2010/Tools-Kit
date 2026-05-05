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
                        guard let folder = manager.addFolder(to: notebookID, name: folderName) else {
                            dismiss()
                            return
                        }

                        // Apply template if selected
                        if let template = selectedTemplate {
                            applyTemplate(template, to: folder.id)
                        }

                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func applyTemplate(_ template: FolderTemplate, to folderID: UUID) {
        switch template {
        case .project:
            manager.addPage(to: folderID, in: notebookID, title: "Project Overview", content: "# Project Overview\n\n- [ ] Goals\n- [ ] Timeline\n- [ ] Stakeholders")
            manager.addPage(to: folderID, in: notebookID, title: "Milestones", content: "# Milestones\n\n1. Initial Design\n2. Prototype\n3. Final Release")
        case .meeting:
            manager.addPage(to: folderID, in: notebookID, title: "Agenda", content: "# Meeting Agenda\n\n- Topic 1\n- Topic 2")
            manager.addPage(to: folderID, in: notebookID, title: "Action Items", content: "# Action Items\n\n- [ ] Action 1")
        case .research:
            manager.addPage(to: folderID, in: notebookID, title: "Bibliography", content: "# Bibliography\n\n- Source 1")
            manager.addPage(to: folderID, in: notebookID, title: "Notes", content: "# Research Notes")
        case .planning:
            manager.addPage(to: folderID, in: notebookID, title: "Roadmap", content: "# Product Roadmap")
            manager.addPage(to: folderID, in: notebookID, title: "Requirements", content: "# Product Requirements Document")
        }
    }
}
