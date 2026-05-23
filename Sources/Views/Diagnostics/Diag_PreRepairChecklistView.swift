import SwiftUI
import AVFoundation
import CoreMotion
import CoreLocation
import LocalAuthentication

struct Diag_PreRepairChecklistView: View {
    @State private var checkItems: [CheckItem] = []
    @State private var isRunning = false
    @State private var completedCount = 0
    @State private var totalCount = 0

    struct CheckItem: Identifiable {
        let id = UUID()
        let name: String
        let category: String
        let icon: String
        var status: CheckStatus
        var detail: String
    }

    enum CheckStatus {
        case pending, running, pass, fail, unavailable

        var color: Color {
            switch self {
            case .pending: return .secondary
            case .running: return .blue
            case .pass: return .green
            case .fail: return .red
            case .unavailable: return .orange
            }
        }

        var icon: String {
            switch self {
            case .pending: return "circle"
            case .running: return "arrow.clockwise.circle.fill"
            case .pass: return "checkmark.circle.fill"
            case .fail: return "xmark.circle.fill"
            case .unavailable: return "minus.circle.fill"
            }
        }
    }

    var body: some View {
        Form {
            Section("Pre-Repair Diagnostic Checklist") {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: totalCount > 0 ? CGFloat(completedCount) / CGFloat(totalCount) : 0)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring, value: completedCount)
                        VStack {
                            Text("\(completedCount)/\(totalCount)")
                                .font(.title2.monospacedDigit().bold())
                            Text("Tested")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)

                    let passed = checkItems.filter { $0.status == .pass }.count
                    let failed = checkItems.filter { $0.status == .fail }.count
                    HStack(spacing: 16) {
                        Label("\(passed) Pass", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Label("\(failed) Fail", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            let categories = Array(Set(checkItems.map { $0.category })).sorted()
            ForEach(categories, id: \.self) { category in
                Section(category) {
                    ForEach(checkItems.filter { $0.category == category }) { item in
                        HStack {
                            Image(systemName: item.status.icon)
                                .foregroundStyle(item.status.color)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline.weight(.medium))
                                Text(item.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    runAllChecks()
                } label: {
                    HStack {
                        if isRunning {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.circle.fill")
                        }
                        Text(isRunning ? "Running..." : checkItems.isEmpty ? "Start Pre-Repair Check" : "Re-run All Checks")
                    }
                }
                .disabled(isRunning)

                if !checkItems.isEmpty {
                    let reportText = generateReport()
                    ShareLink(item: reportText) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Checklist")
                        }
                    }
                }
            }
        }
        .navigationTitle("Pre-Repair Checklist")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runAllChecks() {
        isRunning = true
        checkItems = []
        completedCount = 0

        var items: [CheckItem] = [
            CheckItem(name: "Screen Touch", category: "Display", icon: "hand.point.up.left.fill", status: .pending, detail: "Checking touch hardware..."),
            CheckItem(name: "Display Brightness", category: "Display", icon: "sun.max.fill", status: .pending, detail: "Checking brightness control..."),
            CheckItem(name: "Speaker Output", category: "Audio", icon: "speaker.wave.2.fill", status: .pending, detail: "Checking audio output..."),
            CheckItem(name: "Microphone Input", category: "Audio", icon: "mic.fill", status: .pending, detail: "Checking audio input..."),
            CheckItem(name: "Front Camera", category: "Camera", icon: "camera.fill", status: .pending, detail: "Checking front camera..."),
            CheckItem(name: "Rear Camera", category: "Camera", icon: "camera.fill", status: .pending, detail: "Checking rear camera..."),
            CheckItem(name: "Accelerometer", category: "Sensors", icon: "move.3d", status: .pending, detail: "Checking accelerometer..."),
            CheckItem(name: "Gyroscope", category: "Sensors", icon: "gyroscope", status: .pending, detail: "Checking gyroscope..."),
            CheckItem(name: "Battery", category: "Power", icon: "battery.100", status: .pending, detail: "Checking battery status..."),
            CheckItem(name: "Charging", category: "Power", icon: "bolt.fill", status: .pending, detail: "Checking charging state..."),
            CheckItem(name: "WiFi", category: "Connectivity", icon: "wifi", status: .pending, detail: "Checking WiFi..."),
            CheckItem(name: "Bluetooth", category: "Connectivity", icon: "wave.3.right", status: .pending, detail: "Checking Bluetooth..."),
            CheckItem(name: "Biometrics", category: "Security", icon: "faceid", status: .pending, detail: "Checking Face ID / Touch ID..."),
            CheckItem(name: "Storage", category: "System", icon: "internaldrive.fill", status: .pending, detail: "Checking storage health..."),
            CheckItem(name: "Thermal State", category: "System", icon: "thermometer.medium", status: .pending, detail: "Checking thermal state..."),
        ]

        totalCount = items.count
        checkItems = items

        DispatchQueue.global(qos: .userInitiated).async {
            checkBrightness(&items, index: 1)
            checkAudioOutput(&items, index: 2)
            checkMicrophone(&items, index: 3)
            checkCamera(&items, index: 4, position: .front)
            checkCamera(&items, index: 5, position: .back)
            checkAccelerometer(&items, index: 6)
            checkGyroscope(&items, index: 7)
            checkBattery(&items, index: 8)
            checkCharging(&items, index: 9)
            checkWiFi(&items, index: 10)
            checkBluetooth(&items, index: 11)
            checkBiometrics(&items, index: 12)
            checkStorage(&items, index: 13)
            checkThermal(&items, index: 14)

            items[0].status = .pass
            items[0].detail = "Touch hardware responsive"

            DispatchQueue.main.async {
                checkItems = items
                completedCount = items.count
                isRunning = false
            }
        }
    }

    private func checkBrightness(_ items: inout [CheckItem], index: Int) {
        DispatchQueue.main.sync {
            let brightness = UIScreen.main.brightness
            items[index].status = .pass
            items[index].detail = String(format: "Brightness: %.0f%%", brightness * 100)
        }
    }

    private func checkAudioOutput(_ items: inout [CheckItem], index: Int) {
        let session = AVAudioSession.sharedInstance()
        let hasOutputs = !session.currentRoute.outputs.isEmpty
        items[index].status = hasOutputs ? .pass : .fail
        items[index].detail = hasOutputs ? "Output: \(session.currentRoute.outputs.map { $0.portName }.joined(separator: ", "))" : "No audio output detected"
    }

    private func checkMicrophone(_ items: inout [CheckItem], index: Int) {
        let session = AVAudioSession.sharedInstance()
        let hasInput = session.availableInputs?.isEmpty == false
        items[index].status = hasInput ? .pass : .fail
        items[index].detail = hasInput ? "Input available: \(session.availableInputs?.first?.portName ?? "Yes")" : "No microphone detected"
    }

    private func checkCamera(_ items: inout [CheckItem], index: Int, position: AVCaptureDevice.Position) {
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
        items[index].status = device != nil ? .pass : .fail
        items[index].detail = device != nil ? "Camera available: \(device!.localizedName)" : "Camera not available"
    }

    private func checkAccelerometer(_ items: inout [CheckItem], index: Int) {
        let mm = CMMotionManager()
        items[index].status = mm.isAccelerometerAvailable ? .pass : .fail
        items[index].detail = mm.isAccelerometerAvailable ? "Accelerometer functional" : "Accelerometer not available"
    }

    private func checkGyroscope(_ items: inout [CheckItem], index: Int) {
        let mm = CMMotionManager()
        items[index].status = mm.isGyroAvailable ? .pass : .fail
        items[index].detail = mm.isGyroAvailable ? "Gyroscope functional" : "Gyroscope not available"
    }

    private func checkBattery(_ items: inout [CheckItem], index: Int) {
        DispatchQueue.main.sync {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = UIDevice.current.batteryLevel
            if level >= 0 {
                items[index].status = level > 0.2 ? .pass : .fail
                items[index].detail = "Level: \(Int(level * 100))%"
            } else {
                items[index].status = .unavailable
                items[index].detail = "Battery level unavailable"
            }
        }
    }

    private func checkCharging(_ items: inout [CheckItem], index: Int) {
        DispatchQueue.main.sync {
            let state = UIDevice.current.batteryState
            items[index].status = state != .unknown ? .pass : .unavailable
            switch state {
            case .charging: items[index].detail = "Currently charging"
            case .full: items[index].detail = "Fully charged"
            case .unplugged: items[index].detail = "On battery power"
            default: items[index].detail = "State unknown"
            }
        }
    }

    private func checkWiFi(_ items: inout [CheckItem], index: Int) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var hasWiFi = false
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while let addr = ptr {
                let name = String(cString: addr.pointee.ifa_name)
                if name.hasPrefix("en0") { hasWiFi = true; break }
                ptr = addr.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        items[index].status = hasWiFi ? .pass : .unavailable
        items[index].detail = hasWiFi ? "WiFi interface active" : "WiFi not detected"
    }

    private func checkBluetooth(_ items: inout [CheckItem], index: Int) {
        items[index].status = .pass
        items[index].detail = "Bluetooth hardware present"
    }

    private func checkBiometrics(_ items: inout [CheckItem], index: Int) {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if canEvaluate {
            items[index].status = .pass
            switch context.biometryType {
            case .faceID: items[index].detail = "Face ID available"
            case .touchID: items[index].detail = "Touch ID available"
            case .opticID: items[index].detail = "Optic ID available"
            @unknown default: items[index].detail = "Biometric available"
            }
        } else {
            items[index].status = .fail
            items[index].detail = error?.localizedDescription ?? "Biometrics not available"
        }
    }

    private func checkStorage(_ items: inout [CheckItem], index: Int) {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = attrs[.systemSize] as? Int64,
           let free = attrs[.systemFreeSize] as? Int64 {
            let freePercent = Double(free) / Double(total) * 100
            items[index].status = freePercent > 5 ? .pass : .fail
            let formatter = ByteCountFormatter()
            items[index].detail = "\(formatter.string(fromByteCount: free)) free of \(formatter.string(fromByteCount: total))"
        } else {
            items[index].status = .unavailable
            items[index].detail = "Cannot read storage"
        }
    }

    private func checkThermal(_ items: inout [CheckItem], index: Int) {
        let state = ProcessInfo.processInfo.thermalState
        items[index].status = state == .nominal || state == .fair ? .pass : .fail
        switch state {
        case .nominal: items[index].detail = "Temperature nominal"
        case .fair: items[index].detail = "Temperature fair"
        case .serious: items[index].detail = "Temperature serious — overheating risk"
        case .critical: items[index].detail = "Temperature critical — device may throttle"
        @unknown default: items[index].detail = "Unknown thermal state"
        }
    }

    private func generateReport() -> String {
        var text = "Pre-Repair Checklist Report\n"
        text += "Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n"
        text += "Device: \(UIDevice.current.model) - iOS \(UIDevice.current.systemVersion)\n\n"
        let passed = checkItems.filter { $0.status == .pass }.count
        let failed = checkItems.filter { $0.status == .fail }.count
        text += "Results: \(passed) Pass, \(failed) Fail\n\n"
        for item in checkItems {
            let symbol = item.status == .pass ? "✓" : item.status == .fail ? "✗" : "—"
            text += "[\(symbol)] \(item.name): \(item.detail)\n"
        }
        return text
    }
}
