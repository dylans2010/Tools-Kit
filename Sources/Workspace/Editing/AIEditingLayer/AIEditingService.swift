import Foundation

enum AIEditingPreset: String, CaseIterable, Identifiable {
    case objectRemoval, backgroundGeneration, autoFraming, smartCutDetection, autoColorGrading
    var id: String { rawValue }
}

final class AIEditingService {
    static let shared = AIEditingService()

    func run(preset: AIEditingPreset, projectID: UUID) {
        EditingFramework.shared.record(projectID: projectID, name: "ai_\(preset.rawValue)")
        SyncEngine.shared.enqueue(.init(objectID: projectID, type: "ai_edit", createdAt: Date()))
    }
}
