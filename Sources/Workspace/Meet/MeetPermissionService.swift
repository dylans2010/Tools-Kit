import AVFoundation
import Foundation

struct MeetPermissionService {
    func checkMicrophonePermission() async -> MeetPermissionState {
        await withCheckedContinuation { continuation in
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            switch status {
            case .authorized:
                continuation.resume(returning: .granted)
            case .denied, .restricted:
                continuation.resume(returning: .denied)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted ? .granted : .denied)
                }
            @unknown default:
                continuation.resume(returning: .unknown)
            }
        }
    }

    func checkCameraPermission() async -> MeetPermissionState {
        await withCheckedContinuation { continuation in
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                continuation.resume(returning: .granted)
            case .denied, .restricted:
                continuation.resume(returning: .denied)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted ? .granted : .denied)
                }
            @unknown default:
                continuation.resume(returning: .unknown)
            }
        }
    }
}
