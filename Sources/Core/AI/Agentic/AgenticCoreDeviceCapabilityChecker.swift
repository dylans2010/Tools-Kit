import Foundation

struct AgenticDeviceCapability {
    let isSupported: Bool
    let reason: String?
}

final class AgenticCoreDeviceCapabilityChecker {
    static let shared = AgenticCoreDeviceCapabilityChecker()

    private init() {}

    func checkCapability() -> AgenticDeviceCapability {
        #if targetEnvironment(simulator)
        return AgenticDeviceCapability(isSupported: true, reason: "Running in Simulator (Debug Mode)")
        #else
        // In a real implementation, this would check for Apple Intelligence support,
        // OS version (e.g., iOS 18.0+), and Neural Engine capabilities.
        if #available(iOS 18.0, macOS 15.0, *) {
            // Simplified check: true for demonstration in this environment
            return AgenticDeviceCapability(isSupported: true, reason: nil)
        } else {
            return AgenticDeviceCapability(isSupported: false, reason: "OS version not supported. Requires iOS 18.0+ or macOS 15.0+")
        }
        #endif
    }
}
