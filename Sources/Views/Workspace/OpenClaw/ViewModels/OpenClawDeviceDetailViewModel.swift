import SwiftUI

@MainActor
final class OpenClawDeviceDetailViewModel: ObservableObject {
    let device: OpenClawDevice
    @Published var connectionQuality: Double = 0.0

    init(device: OpenClawDevice) {
        self.device = device
    }

    func deleteDevice() {
        OpenClawDeviceRegistry.shared.remove(device.id)
    }
}
