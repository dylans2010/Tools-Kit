import SwiftUI
import LocalAuthentication

struct Diag_BiometricCheckView: View {
    @State private var biometricType: String = "Checking..."
    @State private var isAvailable = false
    @State private var errorDescription: String?
    @State private var authResult: String?

    var body: some View {
        Form {
            Section("Biometric Authentication") {
                VStack(spacing: 12) {
                    Image(systemName: biometricIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(isAvailable ? .green : .secondary)

                    Text(biometricType)
                        .font(.title2.bold())

                    if let error = errorDescription {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Status") {
                LabeledContent("Available") {
                    Text(isAvailable ? "Yes" : "No")
                        .foregroundStyle(isAvailable ? .green : .red)
                }
                LabeledContent("Type") { Text(biometricType) }
            }

            if isAvailable {
                Section {
                    Button("Test Authentication") {
                        testAuth()
                    }

                    if let result = authResult {
                        Text(result)
                            .font(.subheadline)
                            .foregroundStyle(result.contains("Success") ? .green : .red)
                    }
                }
            }
        }
        .navigationTitle("Biometric Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkBiometrics() }
    }

    private var biometricIcon: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "lock.fill"
        }
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.fill"
        }
    }

    private func checkBiometrics() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isAvailable = true
            switch context.biometryType {
            case .faceID: biometricType = "Face ID"
            case .touchID: biometricType = "Touch ID"
            case .opticID: biometricType = "Optic ID"
            default: biometricType = "Unknown Biometric"
            }
        } else {
            isAvailable = false
            biometricType = "Not Available"
            errorDescription = error?.localizedDescription
        }
    }

    private func testAuth() {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Diagnostics biometric test") { success, error in
            DispatchQueue.main.async {
                if success {
                    authResult = "Success - Authentication passed"
                } else {
                    authResult = "Failed: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
}
