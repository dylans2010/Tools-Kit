import Foundation
import ScreenCaptureKit
import AVFoundation
import Speech

@Observable
class SCKPermissionManager {
    static let shared = SCKPermissionManager()

    var screenCaptureStatus: PermissionStatus = .notDetermined
    var microphoneStatus: PermissionStatus = .notDetermined
    var speechStatus: PermissionStatus = .notDetermined

    enum PermissionStatus: String {
        case notDetermined, denied, authorized, restricted
    }

    private init() {
        checkAllPermissions()
    }

    func checkAllPermissions() {
        checkMicrophonePermission()
        checkSpeechPermission()
        // ScreenCaptureKit permission is implicitly handled by the system picker on iOS.
    }

    private func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: microphoneStatus = .authorized
        case .denied: microphoneStatus = .denied
        case .restricted: microphoneStatus = .restricted
        case .notDetermined: microphoneStatus = .notDetermined
        @unknown default: microphoneStatus = .denied
        }
    }

    private func checkSpeechPermission() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: speechStatus = .authorized
        case .denied: speechStatus = .denied
        case .restricted: speechStatus = .restricted
        case .notDetermined: speechStatus = .notDetermined
        @unknown default: speechStatus = .denied
        }
    }

    func requestMicrophonePermission() async -> Bool {
        let authorized = await AVCaptureDevice.requestAccess(for: .audio)
        microphoneStatus = authorized ? .authorized : .denied
        return authorized
    }

    func requestSpeechPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    self.speechStatus = .authorized
                    continuation.resume(returning: true)
                default:
                    self.speechStatus = .denied
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
