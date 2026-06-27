import Foundation
import AVFoundation

public actor QRPermissionService {
    public static let shared = QRPermissionService()
    private init() {}

    public func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted: return false
        @unknown default: return false
        }
    }
}
