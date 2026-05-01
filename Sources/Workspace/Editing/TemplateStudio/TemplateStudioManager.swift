import Foundation

/// Represents a reusable media project template.
struct EditingTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: String
    let layers: [EditingLayer]
}

/// Manages media project templates.
final class TemplateStudioManager: ObservableObject {
    static let shared = TemplateStudioManager()

    @Published var savedTemplates: [EditingTemplate] = []

    private init() {}

    func saveAsTemplate(project: EditingProject, name: String) {
        let template = EditingTemplate(id: UUID(), name: name, category: "User", layers: project.layers)
        savedTemplates.append(template)
    }

    func applyTemplate(_ template: EditingTemplate, to project: inout EditingProject) {
        project.layers = template.layers
    }
}
