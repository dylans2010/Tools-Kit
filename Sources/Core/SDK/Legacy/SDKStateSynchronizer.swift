import Foundation

/// Syncs SDK state with the live workspace graph.
public final class SDKStateSynchronizer {
    nonisolated(unsafe) public static let shared = SDKStateSynchronizer()

    private init() {}

    public func sync(action: SDKAction) {
        // Updates the local SDK state based on what action was just performed.
        // Ensures real-time consistency between SDK views and real workspace data.
        NotificationCenter.default.post(name: .sdkWorkspaceStateDidUpdate, object: nil, userInfo: ["action": action])
    }
}

extension NSNotification.Name {
    public static let sdkWorkspaceStateDidUpdate = NSNotification.Name("com.toolskit.sdk.workspace.state.update")
}
