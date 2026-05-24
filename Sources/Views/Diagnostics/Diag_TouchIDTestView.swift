import SwiftUI
import LocalAuthentication

struct Diag_TouchIDTestView: View {
    @State private var hasTouchID = false
    @State private var authResult = ""
    @State private var details: [(String, String)] = []
    @State private var isTesting = false

    var body: some View {
        Form {
            Section("Touch ID") {
                VStack(spacing: 12) {
                    Image(systemName: hasTouchID ? "touchid" : "touchid")
                        .font(.system(size: 52))
                        .foregroundStyle(hasTouchID ? .pink : .secondary)
                    Text(hasTouchID ? "Touch ID Available" : "Touch ID Not Available")
                        .font(.headline)
                    Text("Fingerprint sensor diagnostics and authentication test")
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
                    testTouchID()
                } label: {
                    HStack {
                        Image(systemName: "touchid")
                        Text(isTesting ? "Testing..." : "Test Touch ID Authentication")
                    }
                }
                .disabled(isTesting || !hasTouchID)

                if !authResult.isEmpty {
                    LabeledContent("Result") {
                        Text(authResult)
                            .foregroundStyle(authResult == "Success" ? .green : .red)
                    }
                }
            }

            Section("Touch ID Info") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Capacitive fingerprint sensor", systemImage: "touchid").font(.caption)
                    Label("360-degree finger detection", systemImage: "arrow.clockwise").font(.caption)
                    Label("Sapphire crystal protective cover", systemImage: "shield.fill").font(.caption)
                    Label("Up to 5 enrolled fingerprints", systemImage: "hand.raised.fingers.spread.fill").font(.caption)
                    Label("1 in 50,000 false match rate", systemImage: "lock.shield.fill").font(.caption)
                    Label("Used on iPhone SE, older iPhones, iPads", systemImage: "iphone.gen1").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkTouchID() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Touch ID Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkTouchID() }
    }

    private func checkTouchID() {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        var info: [(String, String)] = []
        hasTouchID = canEvaluate && context.biometryType == .touchID

        info.append(("Biometric Type", context.biometryType == .touchID ? "Touch ID" : context.biometryType == .faceID ? "Face ID" : "None"))
        info.append(("Available", canEvaluate ? "Yes" : "No"))
        if let error = error {
            info.append(("Error", error.localizedDescription))
        }
        info.append(("Enrolled", hasTouchID ? "Yes" : "No"))

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        details = info
    }

    private func testTouchID() {
        isTesting = true
        authResult = ""
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Verify Touch ID is working") { success, error in
            DispatchQueue.main.async {
                isTesting = false
                authResult = success ? "Success" : (error?.localizedDescription ?? "Failed")
            }
        }
    }
}
