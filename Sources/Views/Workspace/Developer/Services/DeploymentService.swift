import Foundation

public class DeploymentService: ObservableObject {
    public static let shared = DeploymentService()
    private let store = DeveloperPersistentStore.shared

    @Published public var pipelines: [Pipeline] = []

    private init() { loadPipelines() }

    public func loadPipelines() { self.pipelines = store.pipelines }

    public func triggerPipeline(_ pipeline: Pipeline) async throws {
        var current = store.pipelines
        current.insert(pipeline, at: 0)
        store.savePipelines(current)
        let updatedPipelines = current
        await MainActor.run { self.pipelines = updatedPipelines }
    }
}
