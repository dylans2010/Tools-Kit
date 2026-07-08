import Foundation
#if !targetEnvironment(macCatalyst)
import FamilyControls
#endif

/// Manages Screen Time authorization.
///
/// FamilyControls/Screen Time APIs are unavailable under Mac Catalyst
/// (Apple has never shipped Catalyst support for `AuthorizationCenter`).
/// On Catalyst, this manager reports `.unavailable` rather than silently
/// no-opping, so callers can surface that App Lock/Screen Time features
/// can't run on this build target.
@MainActor
class ScreenTimeAuthorizationManager: ObservableObject {
    static let shared = ScreenTimeAuthorizationManager()

    enum AuthorizationState {
        case notDetermined
        case denied
        case approved
        /// Platform doesn't support Screen Time authorization at all.
        case unavailable
    }

    @Published var isAuthorized: Bool = false
    @Published private(set) var state: AuthorizationState

    #if !targetEnvironment(macCatalyst)
    private let center = AuthorizationCenter.shared
    #endif

    private init() {
        #if targetEnvironment(macCatalyst)
        self.state = .unavailable
        self.isAuthorized = false
        #else
        let status = center.authorizationStatus
        self.state = Self.mapStatus(status)
        self.isAuthorized = status == .approved
        #endif
    }

    func requestAuthorization() async throws {
        #if targetEnvironment(macCatalyst)
        // Nothing to request — surface this as a real error, not a silent success.
        throw ScreenTimeError.unavailableOnCatalyst
        #else
        try await center.requestAuthorization(for: .individual)
        let status = center.authorizationStatus
        self.state = Self.mapStatus(status)
        self.isAuthorized = status == .approved
        #endif
    }

    #if !targetEnvironment(macCatalyst)
    private static func mapStatus(_ status: AuthorizationStatus) -> AuthorizationState {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .approved: return .approved
        @unknown default: return .notDetermined
        }
    }
    #endif
}

enum ScreenTimeError: LocalizedError {
    case unavailableOnCatalyst

    var errorDescription: String? {
        switch self {
        case .unavailableOnCatalyst:
            return "Screen Time / App Lock is not available when running as a Mac Catalyst app."
        }
    }
}
