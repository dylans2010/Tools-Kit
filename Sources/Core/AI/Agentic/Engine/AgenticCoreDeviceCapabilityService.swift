import Foundation
import FoundationModels
import SwiftUI

@MainActor
final class AgenticCoreDeviceCapabilityService: ObservableObject {
    static let shared = AgenticCoreDeviceCapabilityService()

    @Published private(set) var capability: AgenticDeviceCapability = AgenticDeviceCapability(
        isSupported: false,
        requiredReason: "Not yet evaluated",
        deviceClass: "unknown"
    )

    private init() {}

    func evaluate() -> AgenticDeviceCapability {
        let availability = SystemLanguageModel.Availability.current
        let deviceClass = resolveDeviceClass()

        switch availability {
        case .available:
            let cap = AgenticDeviceCapability(
                isSupported: true,
                requiredReason: nil,
                deviceClass: deviceClass
            )
            self.capability = cap
            return cap

        case .unavailable(.deviceNotSupported):
            let cap = AgenticDeviceCapability(
                isSupported: false,
                requiredReason: "This device does not support Apple Intelligence. A device with Apple Silicon and at least 8 GB of RAM is required.",
                deviceClass: deviceClass
            )
            self.capability = cap
            return cap

        case .unavailable(.modelNotReady):
            let cap = AgenticDeviceCapability(
                isSupported: false,
                requiredReason: "Apple Intelligence models are still downloading. Please wait for the download to complete in Settings.",
                deviceClass: deviceClass
            )
            self.capability = cap
            return cap

        case .unavailable(.appleIntelligenceNotEnabled):
            let cap = AgenticDeviceCapability(
                isSupported: false,
                requiredReason: "Apple Intelligence is not enabled. Please enable it in Settings > Apple Intelligence & Siri.",
                deviceClass: deviceClass
            )
            self.capability = cap
            return cap

        case .unavailable:
            let cap = AgenticDeviceCapability(
                isSupported: false,
                requiredReason: "Apple Intelligence is not available on this device.",
                deviceClass: deviceClass
            )
            self.capability = cap
            return cap

        @unknown default:
            let cap = AgenticDeviceCapability(
                isSupported: false,
                requiredReason: "Unable to determine Apple Intelligence availability.",
                deviceClass: deviceClass
            )
            self.capability = cap
            return cap
        }
    }

    private func resolveDeviceClass() -> String {
        #if os(iOS)
        let device = UIDevice.current
        return "\(device.model) (\(device.systemName) \(device.systemVersion))"
        #elseif os(macOS)
        let info = ProcessInfo.processInfo
        return "Mac (\(info.operatingSystemVersionString))"
        #else
        return "Unknown Platform"
        #endif
    }
}
