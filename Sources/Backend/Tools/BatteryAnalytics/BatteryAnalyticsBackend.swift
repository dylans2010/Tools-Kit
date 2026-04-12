import Foundation
import UIKit

final class BatteryAnalyticsBackend: ObservableObject {
    @Published var batteryLevel: Float = 0.0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var isLowPowerMode: Bool = false

    func refresh() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
