import Foundation
import Combine

/// Manages the lifecycle and execution context of SDK-built mini apps.
@MainActor
public final class SDKAppRuntime: ObservableObject {
    public static let shared = SDKAppRuntime()

    @Published public private(set) var activeApps: [UUID: SDKAppInstance] = [:]

    private init() {}

    public func launchApp(manifest: SDKAppManifest) async throws -> UUID {
        let instanceID = UUID()
        let instance = SDKAppInstance(id: instanceID, manifest: manifest)

        activeApps[instanceID] = instance

        SDKLogStore.shared.log("Launching SDK App: \(manifest.name)", source: "SDKAppRuntime", level: .info)

        try await instance.initialize()
        return instanceID
    }

    public func terminateApp(id: UUID) {
        guard let instance = activeApps[id] else { return }
        instance.terminate()
        activeApps.removeValue(forKey: id)
        SDKLogStore.shared.log("Terminated SDK App: \(instance.manifest.name)", source: "SDKAppRuntime", level: .info)
    }
}

public final class SDKAppInstance: Identifiable, ObservableObject {
    public let id: UUID
    public let manifest: SDKAppManifest
    @Published public var state: AppState = .idle

    public enum AppState {
        case idle, initializing, running, suspended, terminated
    }

    init(id: UUID, manifest: SDKAppManifest) {
        self.id = id
        self.manifest = manifest
    }

    func initialize() async throws {
        state = .initializing
        // Real initialization sequence
        for moduleID in manifest.modules {
            let module = try SDKModuleSystem.shared.loadModule(id: moduleID)
            try await module.initialize()
        }

        // Populate initial state from manifest if needed
        SDKStateStore.shared.set(AnyCodable(manifest.version), for: "app.version")

        state = .running
    }

    func terminate() {
        state = .terminated
    }
}
