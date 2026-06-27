import Foundation

public actor LAValidationEngine {
    public static let shared = LAValidationEngine()
    private init() {}

    public func validateDeviceInfo(_ info: LADeviceInfo) -> Bool {
        return !info.appInstallId.isEmpty
    }
}
