import Foundation
import FamilyControls

/// Manages Screen Time authorization.
class ScreenTimeAuthorizationManager: ObservableObject {
    static let shared = ScreenTimeAuthorizationManager()

    @Published var isAuthorized: Bool = false

    private let center = AuthorizationCenter.shared

    private init() {
        self.isAuthorized = center.authorizationStatus == .approved
    }

    func requestAuthorization() async throws {
        try await center.requestAuthorization(for: .individual)
        await MainActor.run {
            self.isAuthorized = center.authorizationStatus == .approved
        }
    }
}
