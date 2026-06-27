import Foundation
import Network
import Observation
import OSLog

@Observable @MainActor
public final class QRScannerViewModel {
    public var hasPermission = false
    private let permissionService = QRPermissionService.shared

    public init() {}

    public func checkPermission() async {
        self.hasPermission = await permissionService.requestCameraPermission()
    }
}
