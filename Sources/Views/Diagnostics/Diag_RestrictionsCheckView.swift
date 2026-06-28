import SwiftUI
import AVFoundation
import CoreLocation
import LocalAuthentication

struct Diag_RestrictionsCheckView: View {
    @State private var restrictions: [(String, String, RestrictionLevel)] = []

    enum RestrictionLevel {
        case allowed, restricted, unknown
        var color: Color { switch self { case .allowed: return .green; case .restricted: return .orange; case .unknown: return .secondary } }
        var icon: String { switch self { case .allowed: return "checkmark.circle.fill"; case .restricted: return "hand.raised.fill"; case .unknown: return "questionmark.circle.fill" } }
    }

    var body: some View {
        Form {
            Section("Device Restrictions") {
                VStack(spacing: 8) {
                    Image(systemName: "hand.raised.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Restriction Scanner")
                        .font(.headline)
                    let restrictedCount = restrictions.filter { $0.2 == .restricted }.count
                    Text(restrictedCount > 0 ? "\(restrictedCount) restrictions detected" : "No restrictions detected")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Feature Restrictions") {
                ForEach(restrictions, id: \.0) { r in
                    HStack {
                        Image(systemName: r.2.icon).foregroundStyle(r.2.color).frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.0).font(.subheadline.weight(.medium))
                            Text(r.1).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("About Restrictions") {
                Text("Restrictions can be set by Screen Time, MDM profiles, or parental controls. Some features may be limited when restrictions are active.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section { Button { checkRestrictions() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") } } }
        }
        .navigationTitle("Restrictions Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkRestrictions() }
    }

    private func checkRestrictions() {
        var results: [(String, String, RestrictionLevel)] = []

        let cameraAuth = AVCaptureDevice.authorizationStatus(for: .video)
        results.append(("Camera", cameraAuth == .restricted ? "Camera is restricted" : "Camera accessible", cameraAuth == .restricted ? .restricted : .allowed))

        let micAuth = AVCaptureDevice.authorizationStatus(for: .audio)
        results.append(("Microphone", micAuth == .restricted ? "Microphone is restricted" : "Microphone accessible", micAuth == .restricted ? .restricted : .allowed))

        let locationAuth = CLLocationManager.authorizationStatus()
        results.append(("Location Services", locationAuth == .restricted ? "Location is restricted" : "Location accessible", locationAuth == .restricted ? .restricted : .allowed))

        let context = LAContext()
        var authError: NSError?
        let hasBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError)
        let biometricRestricted: Bool
        if let laError = authError as? LAError {
            biometricRestricted = laError.code == LAError.Code.biometryLockout
        } else {
            biometricRestricted = false
        }
        results.append(("Biometrics", biometricRestricted ? "Biometrics locked out" : hasBiometrics ? "Biometrics available" : "Biometrics not available", biometricRestricted ? .restricted : hasBiometrics ? .allowed : .unknown))

        let fm = FileManager.default
        let restrictionPaths = [
            "/var/mobile/Library/Preferences/com.apple.applicationaccess.plist",
            "/var/mobile/Library/Preferences/com.apple.springboard.plist"
        ]
        let hasRestrictionFiles = restrictionPaths.contains { fm.fileExists(atPath: $0) }
        results.append(("App Restrictions", hasRestrictionFiles ? "Restriction profile detected" : "No restriction profiles", hasRestrictionFiles ? .restricted : .allowed))

        let canOpenSafari = UIApplication.shared.canOpenURL(URL(string: "http://www.example.com")!)
        results.append(("Web Browsing", canOpenSafari ? "Safari URL scheme accessible" : "Web browsing may be restricted", canOpenSafari ? .allowed : .restricted))

        let canOpenAppStore = UIApplication.shared.canOpenURL(URL(string: "itms-apps://")!)
        results.append(("App Store", canOpenAppStore ? "App Store accessible" : "App Store may be restricted", canOpenAppStore ? .allowed : .restricted))

        restrictions = results
    }
}
