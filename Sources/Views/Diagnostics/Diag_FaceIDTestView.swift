import SwiftUI
import LocalAuthentication

struct Diag_FaceIDTestView: View {
    @State private var hasFaceID = false
    @State private var authResult = ""
    @State private var details: [(String, String)] = []
    @State private var isTesting = false

    var body: some View {
        Form {
            Section("Face ID") {
                VStack(spacing: 12) {
                    Image(systemName: hasFaceID ? "faceid" : "faceid")
                        .font(.system(size: 52))
                        .foregroundStyle(hasFaceID ? .green : .secondary)
                    Text(hasFaceID ? "Face ID Available" : "Face ID Not Available")
                        .font(.headline)
                    Text("Test Face ID enrollment, authentication, and TrueDepth hardware")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Biometric Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Authentication Test") {
                Button {
                    testFaceID()
                } label: {
                    HStack {
                        Image(systemName: "faceid")
                        Text(isTesting ? "Testing..." : "Test Face ID Authentication")
                    }
                }
                .disabled(isTesting || !hasFaceID)

                if !authResult.isEmpty {
                    LabeledContent("Result") {
                        Text(authResult)
                            .foregroundStyle(authResult == "Success" ? .green : .red)
                    }
                }
            }

            Section("Face ID Info") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("TrueDepth camera with IR emitter", systemImage: "camera.filters").font(.caption)
                    Label("30,000+ IR dots for face mapping", systemImage: "circle.grid.3x3.fill").font(.caption)
                    Label("1 in 1,000,000 false match rate", systemImage: "lock.shield.fill").font(.caption)
                    Label("Works with glasses, hats, beards", systemImage: "eyeglasses").font(.caption)
                    Label("Attention awareness for security", systemImage: "eye.fill").font(.caption)
                    Label("Mask support (iOS 15.4+)", systemImage: "facemask.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkFaceID() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Face ID Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkFaceID() }
    }

    private func checkFaceID() {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        var info: [(String, String)] = []
        hasFaceID = canEvaluate && context.biometryType == .faceID

        info.append(("Biometric Type", biometryName(context.biometryType)))
        info.append(("Available", canEvaluate ? "Yes" : "No"))
        if let error = error {
            info.append(("Error", error.localizedDescription))
        }
        info.append(("Enrolled", hasFaceID ? "Yes" : "No"))

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        details = info
    }

    private func biometryName(_ type: LABiometryType) -> String {
        switch type {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "None"
        }
    }

    private func testFaceID() {
        isTesting = true
        authResult = ""
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Verify Face ID is working") { success, error in
            DispatchQueue.main.async {
                isTesting = false
                if success {
                    authResult = "Success"
                } else {
                    authResult = error?.localizedDescription ?? "Failed"
                }
            }
        }
    }
}
