import Foundation

enum CloudKitError: LocalizedError {
    case icloudUnavailable
    case accountStatusUnknown
    case permissionDenied
    case networkUnavailable
    case recordNotFound
    case quotaExceeded
    case conflict
    case internalError(String)

    var errorDescription: String? {
        switch self {
        case .icloudUnavailable: return "iCloud is not available or not logged in."
        case .accountStatusUnknown: return "Could not determine iCloud account status."
        case .permissionDenied: return "iCloud permissions were denied."
        case .networkUnavailable: return "Network is unavailable for CloudKit operations."
        case .recordNotFound: return "Requested record was not found in CloudKit."
        case .quotaExceeded: return "CloudKit storage quota exceeded."
        case .conflict: return "A conflict occurred while saving to CloudKit."
        case .internalError(let message): return "CloudKit Internal Error: \(message)"
        }
    }
}
