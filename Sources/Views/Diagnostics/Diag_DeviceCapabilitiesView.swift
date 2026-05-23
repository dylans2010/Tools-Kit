import SwiftUI
import AVFoundation
import CoreHaptics
import CoreLocation
import LocalAuthentication
import CoreNFC
import ARKit
import CoreMotion
import Metal

struct Diag_DeviceCapabilitiesView: View {
    @State private var capabilities: [CapabilityGroup] = []

    struct CapabilityGroup: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let items: [CapabilityItem]
    }

    struct CapabilityItem: Identifiable {
        let id = UUID()
        let name: String
        let available: Bool
        let detail: String?
    }

    var body: some View {
        Form {
            ForEach(capabilities) { group in
                Section {
                    ForEach(group.items) { item in
                        HStack {
                            Image(systemName: item.available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(item.available ? .green : .red)
                                .font(.body)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline)
                                if let detail = item.detail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: group.icon)
                        Text(group.name)
                    }
                }
            }

            Section("Summary") {
                let total = capabilities.flatMap(\.items).count
                let available = capabilities.flatMap(\.items).filter(\.available).count
                LabeledContent("Total Capabilities") { Text("\(total)") }
                LabeledContent("Available") {
                    Text("\(available)")
                        .foregroundStyle(.green)
                }
                LabeledContent("Not Available") {
                    Text("\(total - available)")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Device Capabilities")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadCapabilities() }
    }

    private func loadCapabilities() {
        let camera = CapabilityGroup(name: "Camera", icon: "camera.fill", items: [
            CapabilityItem(name: "Rear Camera", available: UIImagePickerController.isCameraDeviceAvailable(.rear), detail: nil),
            CapabilityItem(name: "Front Camera", available: UIImagePickerController.isCameraDeviceAvailable(.front), detail: nil),
            CapabilityItem(name: "Flash", available: AVCaptureDevice.default(for: .video)?.hasFlash ?? false, detail: nil),
            CapabilityItem(name: "Torch", available: AVCaptureDevice.default(for: .video)?.hasTorch ?? false, detail: nil),
            CapabilityItem(name: "LiDAR", available: ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh), detail: "Depth sensing"),
            CapabilityItem(name: "TrueDepth", available: ARFaceTrackingConfiguration.isSupported, detail: "Face tracking"),
        ])

        let sensors = CapabilityGroup(name: "Sensors", icon: "sensor.fill", items: [
            CapabilityItem(name: "Accelerometer", available: CMMotionManager().isAccelerometerAvailable, detail: nil),
            CapabilityItem(name: "Gyroscope", available: CMMotionManager().isGyroAvailable, detail: nil),
            CapabilityItem(name: "Magnetometer", available: CMMotionManager().isMagnetometerAvailable, detail: nil),
            CapabilityItem(name: "Barometer", available: CMAltimeter.isRelativeAltitudeAvailable(), detail: "Altitude & pressure"),
            CapabilityItem(name: "Proximity Sensor", available: UIDevice.current.isProximityMonitoringEnabled || true, detail: nil),
            CapabilityItem(name: "GPS", available: CLLocationManager.locationServicesEnabled(), detail: nil),
            CapabilityItem(name: "Compass", available: CLLocationManager.headingAvailable(), detail: nil),
        ])

        let haptics = CapabilityGroup(name: "Haptics & Audio", icon: "hand.tap.fill", items: [
            CapabilityItem(name: "Haptic Engine", available: CHHapticEngine.capabilitiesForHardware().supportsHaptics, detail: nil),
            CapabilityItem(name: "Audio Playback", available: true, detail: nil),
            CapabilityItem(name: "Microphone", available: AVAudioSession.sharedInstance().isInputAvailable, detail: nil),
        ])

        let context = LAContext()
        var biometricError: NSError?
        let biometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &biometricError)
        let biometricType = context.biometryType

        let security = CapabilityGroup(name: "Security", icon: "lock.shield.fill", items: [
            CapabilityItem(name: "Face ID", available: biometricAvailable && biometricType == .faceID, detail: nil),
            CapabilityItem(name: "Touch ID", available: biometricAvailable && biometricType == .touchID, detail: nil),
            CapabilityItem(name: "Secure Enclave", available: true, detail: "Hardware security module"),
            CapabilityItem(name: "NFC", available: NFCNDEFReaderSession.readingAvailable, detail: nil),
        ])

        let metalDevice = MTLCreateSystemDefaultDevice()
        let gpu = CapabilityGroup(name: "GPU & Display", icon: "gpu", items: [
            CapabilityItem(name: "Metal", available: metalDevice != nil, detail: metalDevice?.name),
            CapabilityItem(name: "Metal GPU Family Apple 7+", available: metalDevice?.supportsFamily(.apple7) ?? false, detail: nil),
            CapabilityItem(name: "ProMotion (120Hz)", available: UIScreen.main.maximumFramesPerSecond >= 120, detail: "\(UIScreen.main.maximumFramesPerSecond) Hz max"),
            CapabilityItem(name: "HDR Display", available: UIScreen.main.responds(to: Selector(("currentEDRHeadroom"))), detail: nil),
        ])

        let connectivity = CapabilityGroup(name: "Connectivity", icon: "wifi", items: [
            CapabilityItem(name: "WiFi", available: true, detail: nil),
            CapabilityItem(name: "Bluetooth", available: true, detail: nil),
            CapabilityItem(name: "Cellular", available: hasCellularCapability(), detail: nil),
            CapabilityItem(name: "Ultra Wideband (UWB)", available: hasUWB(), detail: "Spatial awareness"),
        ])

        capabilities = [camera, sensors, haptics, security, gpu, connectivity]
    }

    private func hasCellularCapability() -> Bool {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return false }
        defer { freeifaddrs(ifaddr) }
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            if name.hasPrefix("pdp_ip") { return true }
            ptr = addr.pointee.ifa_next
        }
        return false
    }

    private func hasUWB() -> Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
        // iPhone 11+ (iPhone12,x and above) has UWB
        if identifier.hasPrefix("iPhone") {
            let numberPart = identifier.replacingOccurrences(of: "iPhone", with: "")
            if let majorStr = numberPart.split(separator: ",").first, let major = Int(majorStr) {
                return major >= 12
            }
        }
        return false
    }
}
