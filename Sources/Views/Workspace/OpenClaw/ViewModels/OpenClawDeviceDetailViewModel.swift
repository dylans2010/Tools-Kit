import SwiftUI
import Observation

@MainActor @Observable
final class OpenClawDeviceDetailViewModel {
    let device: OpenClawDevice
    var connectionQuality: Double = 0.0

    init(device: OpenClawDevice) {
        self.device = device
    }

    func deleteDevice() {
        OpenClawDeviceRegistry.shared.remove(device.id)
    }
}
