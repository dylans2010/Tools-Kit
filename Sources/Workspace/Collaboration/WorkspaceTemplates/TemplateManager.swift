import Foundation

/// Represents a reusable template for a collaboration space.
struct SpaceTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let category: TemplateCategory
    let snapshotData: Data // Encoded CollaborationSpace state

    enum TemplateCategory: String, Codable, CaseIterable {
        case startup = "Startup"
        case study = "Study"
        case project = "Project"
        case creative = "Content Creation"
    }
}

/// Manages the creation and application of space templates.
final class TemplateManager: ObservableObject {
    static let shared = TemplateManager()

    @Published var templates: [SpaceTemplate] = []

    private init() {
        setupDefaultTemplates()
    }

    func saveAsTemplate(space: CollaborationSpace, name: String, category: SpaceTemplate.TemplateCategory) {
        if let data = try? JSONEncoder().encode(space) {
            let template = SpaceTemplate(
                id: UUID(),
                name: name,
                description: space.description,
                icon: space.icon,
                category: category,
                snapshotData: data
            )
            templates.append(template)
        }
    }

    func createSpaceFromTemplate(_ template: SpaceTemplate) -> CollaborationSpace? {
        guard var space = try? JSONDecoder().decode(CollaborationSpace.self, from: template.snapshotData) else { return nil }

        // Assign new ID and reset history for the new instance
        let newSpace = CollaborationSpace(
            id: UUID(),
            name: "New \(template.name)",
            description: template.description,
            icon: template.icon,
            visibility: .privateSpace,
            members: [],
            branches: space.branches,
            currentBranchID: space.currentBranchID,
            activityFeed: [],
            notebookIDs: space.notebookIDs,
            slideDeckIDs: space.slideDeckIDs,
            meetingIDs: space.meetingIDs,
            formIDs: space.formIDs,
            spreadsheetIDs: space.spreadsheetIDs,
            mediaProjectIDs: space.mediaProjectIDs,
            createdAt: Date(),
            updatedAt: Date()
        )

        CollaborationManager.shared.spaces.append(newSpace)
        return newSpace
    }

    private func setupDefaultTemplates() {
        // Add some pre-defined templates if empty
    }
}
