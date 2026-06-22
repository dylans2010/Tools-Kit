import SwiftUI
import LocalAuthentication
import AVFoundation

struct Diag_FaceIDDiagnosticsView: View {
    @State private var faceIDAvailable = false
    @State private var biometryType: LABiometryType = .none
    @State private var errorMessage: String?
    @State private var authTestResult: String?
    @State private var trueDepthAvailable = false
    @State private var frontCameraDetails: [(String, String)] = []

    var body: some View {
        List {
            Section("Face ID Status") {
                VStack(spacing: 12) {
                    Image(systemName: faceIDAvailable ? "faceid" : "faceid")
                        .font(.system(size: 60))
                        .foregroundStyle(faceIDAvailable ? .green : .secondary)
                    Text(faceIDAvailable ? "Face ID Available" : biometryType == .touchID ? "Touch ID Device" : "Face ID Not Available")
                        .font(.headline)
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("TrueDepth Camera System") {
                LabeledContent("TrueDepth Camera") {
                    Text(trueDepthAvailable ? "Available" : "Not Available")
                        .foregroundStyle(trueDepthAvailable ? .green : .red)
                }
                LabeledContent("Biometry Type") {
                    Text(biometryTypeString)
                }
                LabeledContent("Enrolled Faces") {
                    Text(faceIDAvailable ? "Face data enrolled" : "No face enrolled")
                        .foregroundStyle(faceIDAvailable ? .green : .secondary)
                }
            }

            if !frontCameraDetails.isEmpty {
                Section("Front Camera Hardware") {
                    ForEach(frontCameraDetails, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("TrueDepth Components") {
                VStack(alignment: .leading, spacing: 8) {
                    ComponentRow(name: "Infrared Camera", available: trueDepthAvailable, detail: "Reads IR dot pattern")
                    ComponentRow(name: "Flood Illuminator", available: trueDepthAvailable, detail: "Invisible IR light")
                    ComponentRow(name: "Dot Projector", available: trueDepthAvailable, detail: "Projects 30,000+ dots")
                    ComponentRow(name: "Proximity Sensor", available: true, detail: "Wakes TrueDepth system")
                    ComponentRow(name: "Ambient Light Sensor", available: true, detail: "Adapts to lighting")
                }
                .padding(.vertical, 4)
            }

            if faceIDAvailable {
                Section("Authentication Test") {
                    Button {
                        testFaceID()
                    } label: {
                        HStack {
                            Image(systemName: "faceid")
                            Text("Test Face ID Authentication")
                        }
                    }

                    if let result = authTestResult {
                        Text(result)
                            .font(.subheadline)
                            .foregroundStyle(result.contains("Success") ? .green : .red)
                    }
                }
            }

            Section("Troubleshooting") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Clean the TrueDepth camera area", systemImage: "sparkles")
                        .font(.caption)
                    Label("Remove screen protectors covering the notch/island", systemImage: "rectangle.slash")
                        .font(.caption)
                    Label("Reset Face ID: Settings → Face ID & Passcode → Reset", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                    Label("Ensure nothing blocks the TrueDepth camera", systemImage: "eye.slash")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Face ID Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkFaceID() }
    }

    private var biometryTypeString: String {
        switch biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "None"
        @unknown default: return "Unknown"
        }
    }

    private func checkFaceID() {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        faceIDAvailable = canEvaluate && context.biometryType == .faceID
        biometryType = context.biometryType
        errorMessage = error?.localizedDescription

        if let frontCamera = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
            trueDepthAvailable = true
            var details: [(String, String)] = []
            details.append(("Camera", frontCamera.localizedName))
            details.append(("Model ID", frontCamera.modelID))
            details.append(("Position", "Front"))
            let formats = frontCamera.formats
            if let bestFormat = formats.last {
                let dim = CMVideoFormatDescriptionGetDimensions(bestFormat.formatDescription)
                details.append(("Max Resolution", "\(dim.width)×\(dim.height)"))
            }
            details.append(("Torch", frontCamera.isTorchAvailable ? "Yes" : "No"))
            details.append(("Low Light Boost", frontCamera.isLowLightBoostSupported ? "Yes" : "No"))
            frontCameraDetails = details
        } else if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            trueDepthAvailable = false
            var details: [(String, String)] = []
            details.append(("Camera", wideCamera.localizedName))
            details.append(("TrueDepth", "Not available"))
            details.append(("Type", "Standard front camera"))
            frontCameraDetails = details
        }
    }

    private func testFaceID() {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Diagnostic Face ID test") { success, error in
            DispatchQueue.main.async {
                if success {
                    authTestResult = "Success — Face ID authentication passed"
                } else {
                    authTestResult = "Failed: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
}

private struct ComponentRow: View {
    let name: String
    let available: Bool
    let detail: String

    var body: some View {
        HStack {
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(available ? .green : .red)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.caption.weight(.medium))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
