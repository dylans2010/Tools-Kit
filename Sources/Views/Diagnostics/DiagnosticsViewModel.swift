import SwiftUI
import Combine

struct DiagnosticTool: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let category: DiagnosticCategory

    static func == (lhs: DiagnosticTool, rhs: DiagnosticTool) -> Bool {
        lhs.id == rhs.id
    }
}

enum DiagnosticCategory: String, CaseIterable, Identifiable {
    case display = "Display"
    case audio = "Audio"
    case microphone = "Microphone"
    case sensors = "Sensors"
    case haptics = "Haptics"
    case connectivity = "Connectivity"
    case performance = "Performance"
    case battery = "Battery"
    case camera = "Camera"
    case storage = "Storage"
    case system = "System"
    case accessibility = "Accessibility"
    case security = "Security"
    case location = "Location"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .display: return "display"
        case .audio: return "speaker.wave.3.fill"
        case .microphone: return "mic.fill"
        case .sensors: return "sensor.fill"
        case .haptics: return "hand.tap.fill"
        case .connectivity: return "wifi"
        case .performance: return "gauge.with.dots.needle.67percent"
        case .battery: return "battery.100"
        case .camera: return "camera.fill"
        case .storage: return "internaldrive.fill"
        case .system: return "gearshape.fill"
        case .accessibility: return "accessibility"
        case .security: return "lock.shield.fill"
        case .location: return "location.fill"
        }
    }

    var tint: Color {
        switch self {
        case .display: return .blue
        case .audio: return .orange
        case .microphone: return .red
        case .sensors: return .purple
        case .haptics: return .pink
        case .connectivity: return .green
        case .performance: return .yellow
        case .battery: return .mint
        case .camera: return .indigo
        case .storage: return .teal
        case .system: return .gray
        case .accessibility: return .cyan
        case .security: return .brown
        case .location: return .blue
        }
    }
}

final class DiagnosticsViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: DiagnosticCategory?

    let allTools: [DiagnosticTool] = [
        // Display (7)
        DiagnosticTool(id: "screen_color", name: "Screen Color Test", icon: "paintpalette.fill", description: "Cycle through RGB colors to check display uniformity", category: .display),
        DiagnosticTool(id: "dead_pixel", name: "Dead Pixel Detection", icon: "square.grid.3x3.fill", description: "Detect dead or stuck pixels on your display", category: .display),
        DiagnosticTool(id: "brightness", name: "Brightness Test", icon: "sun.max.fill", description: "Test display brightness range and uniformity", category: .display),
        DiagnosticTool(id: "touch_response", name: "Touch Responsiveness", icon: "hand.point.up.left.fill", description: "Test touch screen response accuracy", category: .display),
        DiagnosticTool(id: "multi_touch", name: "Multi-Touch Tracking", icon: "hand.point.up.fill", description: "Track multiple simultaneous touch points", category: .display),
        DiagnosticTool(id: "true_tone", name: "True Tone Check", icon: "circle.lefthalf.filled", description: "Check True Tone display adaptation status", category: .display),
        DiagnosticTool(id: "color_accuracy", name: "Color Accuracy", icon: "eyedropper.halffull", description: "Evaluate display color accuracy with test patterns", category: .display),

        // Audio (5)
        DiagnosticTool(id: "speaker_test", name: "Speaker L/R Test", icon: "speaker.wave.2.fill", description: "Test left and right speaker channels independently", category: .audio),
        DiagnosticTool(id: "stereo_balance", name: "Stereo Balance", icon: "slider.horizontal.3", description: "Verify stereo audio balance between channels", category: .audio),
        DiagnosticTool(id: "volume_ramp", name: "Volume Ramp Test", icon: "speaker.wave.3.fill", description: "Test speaker volume ramp from silent to max", category: .audio),
        DiagnosticTool(id: "distortion", name: "Distortion Detection", icon: "waveform.badge.exclamationmark", description: "Detect audio distortion during playback", category: .audio),
        DiagnosticTool(id: "audio_latency", name: "Audio Latency", icon: "clock.arrow.2.circlepath", description: "Measure audio output latency", category: .audio),

        // Microphone (4)
        DiagnosticTool(id: "mic_level", name: "Mic Input Level", icon: "mic.fill", description: "Visualize real-time microphone input levels", category: .microphone),
        DiagnosticTool(id: "noise_detect", name: "Noise Detection", icon: "ear.fill", description: "Analyze ambient noise levels and patterns", category: .microphone),
        DiagnosticTool(id: "recording_test", name: "Recording Test", icon: "waveform.circle.fill", description: "Record audio and play it back to verify quality", category: .microphone),
        DiagnosticTool(id: "mic_switch", name: "Multi-Mic Switching", icon: "mic.badge.plus", description: "Test switching between available microphones", category: .microphone),

        // Sensors (5)
        DiagnosticTool(id: "accelerometer", name: "Accelerometer", icon: "move.3d", description: "Live graph of accelerometer X, Y, Z data", category: .sensors),
        DiagnosticTool(id: "gyroscope", name: "Gyroscope", icon: "gyroscope", description: "Visualize gyroscope rotation rate data", category: .sensors),
        DiagnosticTool(id: "magnetometer", name: "Magnetometer", icon: "location.north.fill", description: "Raw compass and magnetic field data", category: .sensors),
        DiagnosticTool(id: "proximity", name: "Proximity Sensor", icon: "hand.raised.fill", description: "Test proximity sensor activation", category: .sensors),
        DiagnosticTool(id: "ambient_light", name: "Ambient Light", icon: "light.max", description: "Monitor ambient light sensor readings", category: .sensors),

        // Haptics (3)
        DiagnosticTool(id: "haptic_test", name: "Haptic Feedback", icon: "hand.tap.fill", description: "Test various haptic feedback intensities", category: .haptics),
        DiagnosticTool(id: "haptic_pattern", name: "Pattern Playback", icon: "waveform.path", description: "Play haptic patterns to verify motor function", category: .haptics),
        DiagnosticTool(id: "taptic_engine", name: "Taptic Engine Test", icon: "iphone.radiowaves.left.and.right", description: "Comprehensive Taptic Engine diagnostic", category: .haptics),

        // Connectivity (5)
        DiagnosticTool(id: "wifi_strength", name: "WiFi Strength", icon: "wifi", description: "Measure current WiFi signal and connection quality", category: .connectivity),
        DiagnosticTool(id: "network_latency", name: "Network Latency", icon: "network", description: "Ping simulation to measure network latency", category: .connectivity),
        DiagnosticTool(id: "internet_speed", name: "Internet Speed", icon: "speedometer", description: "Approximate upload and download speed", category: .connectivity),
        DiagnosticTool(id: "bluetooth", name: "Bluetooth Scanner", icon: "wave.3.right", description: "Check Bluetooth availability and scan for devices", category: .connectivity),
        DiagnosticTool(id: "airplane", name: "Airplane Mode", icon: "airplane", description: "Detect airplane mode and network interface status", category: .connectivity),

        // Performance (5)
        DiagnosticTool(id: "cpu_stress", name: "CPU Stress Test", icon: "cpu", description: "Safe CPU load simulation with real-time metrics", category: .performance),
        DiagnosticTool(id: "memory_usage", name: "Memory Usage", icon: "memorychip", description: "Display current memory allocation and pressure", category: .performance),
        DiagnosticTool(id: "fps_monitor", name: "FPS Monitor", icon: "gauge.with.dots.needle.67percent", description: "Real-time frame rate monitoring", category: .performance),
        DiagnosticTool(id: "thermal_state", name: "Thermal State", icon: "thermometer.medium", description: "Monitor device thermal state in real time", category: .performance),
        DiagnosticTool(id: "process_info", name: "Process Info", icon: "chart.bar.fill", description: "View active process and system resource details", category: .performance),

        // Battery (3)
        DiagnosticTool(id: "battery_level", name: "Battery Health", icon: "battery.100", description: "Battery level, state, and health information", category: .battery),
        DiagnosticTool(id: "charging_state", name: "Charging State", icon: "bolt.fill", description: "Monitor charging status and power source", category: .battery),
        DiagnosticTool(id: "battery_drain", name: "Battery Drain Sim", icon: "battery.25", description: "Visual simulation of battery drain over time", category: .battery),

        // Camera (4)
        DiagnosticTool(id: "front_camera", name: "Front Camera", icon: "camera.fill", description: "Preview and test front-facing camera", category: .camera),
        DiagnosticTool(id: "rear_camera", name: "Rear Camera", icon: "camera.fill", description: "Preview and test rear-facing camera", category: .camera),
        DiagnosticTool(id: "focus_test", name: "Focus Test", icon: "camera.metering.center.weighted", description: "Test camera autofocus and manual focus", category: .camera),
        DiagnosticTool(id: "flash_test", name: "Flash Test", icon: "bolt.circle.fill", description: "Test camera flash/torch functionality", category: .camera),

        // Storage (3)
        DiagnosticTool(id: "disk_usage", name: "Disk Usage", icon: "internaldrive.fill", description: "Detailed breakdown of disk space usage", category: .storage),
        DiagnosticTool(id: "rw_test", name: "Read/Write Test", icon: "doc.badge.gearshape", description: "Simulate disk read and write speed test", category: .storage),
        DiagnosticTool(id: "file_system", name: "File System Info", icon: "folder.fill.badge.gearshape", description: "View file system details and attributes", category: .storage),

        // System (5)
        DiagnosticTool(id: "device_info", name: "Device Info", icon: "iphone", description: "Model, iOS version, and hardware identifiers", category: .system),
        DiagnosticTool(id: "uptime", name: "System Uptime", icon: "clock.fill", description: "View how long the device has been running", category: .system),
        DiagnosticTool(id: "permissions", name: "Permissions Checker", icon: "checkmark.shield.fill", description: "Audit app permissions for camera, mic, location, etc.", category: .system),
        DiagnosticTool(id: "locale_info", name: "Locale & Region", icon: "globe", description: "Current locale, language, and region settings", category: .system),
        DiagnosticTool(id: "notifications", name: "Notification Status", icon: "bell.badge.fill", description: "Check push notification authorization status", category: .system),

        // Accessibility (3)
        DiagnosticTool(id: "voiceover", name: "VoiceOver Status", icon: "speaker.badge.exclamationmark.fill", description: "Check if VoiceOver accessibility is enabled", category: .accessibility),
        DiagnosticTool(id: "dynamic_type", name: "Dynamic Type", icon: "textformat.size", description: "Test current Dynamic Type text size settings", category: .accessibility),
        DiagnosticTool(id: "reduce_motion", name: "Reduce Motion", icon: "figure.walk", description: "Check reduce motion and transparency settings", category: .accessibility),

        // Security (5)
        DiagnosticTool(id: "biometric", name: "Biometric Check", icon: "faceid", description: "Test Face ID or Touch ID availability", category: .security),
        DiagnosticTool(id: "passcode", name: "Passcode Status", icon: "lock.fill", description: "Check if device passcode is set", category: .security),
        DiagnosticTool(id: "secure_enclave", name: "Secure Enclave", icon: "lock.shield.fill", description: "Verify Secure Enclave availability", category: .security),
        DiagnosticTool(id: "jailbreak", name: "Jailbreak Detection", icon: "exclamationmark.shield.fill", description: "Check device for jailbreak indicators", category: .security),
        DiagnosticTool(id: "ats_check", name: "ATS Check", icon: "lock.doc.fill", description: "Verify App Transport Security configuration", category: .security),
        DiagnosticTool(id: "keychain_check", name: "Keychain Check", icon: "key.fill", description: "Test Keychain read/write and encryption", category: .security),

        // Display (new)
        DiagnosticTool(id: "refresh_rate", name: "Refresh Rate", icon: "arrow.clockwise", description: "Detect display refresh rate and ProMotion", category: .display),
        DiagnosticTool(id: "hdr_display", name: "HDR Display", icon: "sun.max.trianglebadge.exclamationmark.fill", description: "Check HDR and wide color gamut support", category: .display),
        DiagnosticTool(id: "display_zoom", name: "Display Zoom", icon: "plus.magnifyingglass", description: "Detect Display Zoom mode and screen metrics", category: .display),

        // Audio (new)
        DiagnosticTool(id: "spatial_audio", name: "Spatial Audio", icon: "ear.fill", description: "Check Spatial Audio and Dolby Atmos support", category: .audio),
        DiagnosticTool(id: "audio_routing", name: "Audio Routing", icon: "arrow.triangle.branch", description: "View current audio input/output routing", category: .audio),

        // Microphone (new)
        DiagnosticTool(id: "voice_isolation", name: "Voice Isolation", icon: "person.wave.2.fill", description: "Test voice isolation and noise suppression", category: .microphone),

        // Sensors (new)
        DiagnosticTool(id: "barometer", name: "Barometer", icon: "barometer", description: "Measure atmospheric pressure and altitude", category: .sensors),
        DiagnosticTool(id: "pedometer", name: "Pedometer", icon: "figure.walk", description: "Track steps, distance, and floors climbed", category: .sensors),
        DiagnosticTool(id: "motion_activity", name: "Motion Activity", icon: "figure.run", description: "Detect walking, running, driving activity", category: .sensors),

        // Connectivity (new)
        DiagnosticTool(id: "cellular_info", name: "Cellular Info", icon: "antenna.radiowaves.left.and.right", description: "Carrier, radio technology, and signal info", category: .connectivity),
        DiagnosticTool(id: "nfc_check", name: "NFC Check", icon: "wave.3.right.circle.fill", description: "Check NFC reading capability", category: .connectivity),
        DiagnosticTool(id: "vpn_status", name: "VPN Status", icon: "lock.shield.fill", description: "Detect active VPN connections and tunnels", category: .connectivity),
        DiagnosticTool(id: "network_info", name: "Network Info", icon: "network", description: "View network interfaces, IPs, and DNS", category: .connectivity),

        // Performance (new)
        DiagnosticTool(id: "gpu_info", name: "GPU Info", icon: "gpu", description: "Metal GPU capabilities and memory info", category: .performance),
        DiagnosticTool(id: "app_launch", name: "App Launch Time", icon: "timer", description: "Benchmark operation speed and launch metrics", category: .performance),

        // Battery (new)
        DiagnosticTool(id: "low_power", name: "Low Power Mode", icon: "bolt.circle.fill", description: "Check Low Power Mode status and impact", category: .battery),

        // Camera (new)
        DiagnosticTool(id: "zoom_range", name: "Zoom Range", icon: "camera.aperture", description: "Test camera zoom capabilities and lenses", category: .camera),
        DiagnosticTool(id: "lidar_check", name: "LiDAR Check", icon: "dot.radiowaves.left.and.right", description: "Check LiDAR scanner and depth sensing", category: .camera),
        DiagnosticTool(id: "truedepth", name: "TrueDepth Camera", icon: "faceid", description: "Test TrueDepth camera and Face ID hardware", category: .camera),

        // Storage (new)
        DiagnosticTool(id: "cache_size", name: "Cache Size", icon: "archivebox.fill", description: "Analyze app cache and temp storage usage", category: .storage),
        DiagnosticTool(id: "storage_health", name: "Storage Health", icon: "heart.text.square.fill", description: "Storage capacity, I/O speed, and health", category: .storage),

        // System (new)
        DiagnosticTool(id: "bg_refresh", name: "Background Refresh", icon: "arrow.clockwise.circle.fill", description: "Check Background App Refresh status", category: .system),
        DiagnosticTool(id: "screen_time", name: "Screen Time", icon: "hourglass.circle.fill", description: "View session time and display metrics", category: .system),
        DiagnosticTool(id: "hw_buttons", name: "Hardware Buttons", icon: "iphone.gen3", description: "Test volume buttons and silent switch", category: .system),

        // Accessibility (new)
        DiagnosticTool(id: "bold_text", name: "Bold Text", icon: "bold", description: "Check if system bold text is enabled", category: .accessibility),
        DiagnosticTool(id: "color_filters", name: "Color Filters", icon: "circle.lefthalf.filled", description: "Detect active color filters and inversions", category: .accessibility),

        // Location (4)
        DiagnosticTool(id: "gps_signal", name: "GPS Signal", icon: "location.fill", description: "Detailed GPS coordinates, accuracy and signal strength", category: .location),
        DiagnosticTool(id: "satellite_conn", name: "Satellite Connectivity", icon: "satellite.fill", description: "Check satellite connectivity status for iPhone 14+", category: .location),
        DiagnosticTool(id: "heading", name: "Compass & Heading", icon: "location.north.line.fill", description: "Verify true north and magnetic heading accuracy", category: .location),
        DiagnosticTool(id: "altimeter", name: "Altimeter", icon: "mountain.2.fill", description: "Relative altitude and barometric pressure tracking", category: .location),

        // Connectivity Expanded (6)
        DiagnosticTool(id: "dns_latency", name: "DNS Latency", icon: "server.rack", description: "Measure DNS resolution time across various providers", category: .connectivity),
        DiagnosticTool(id: "signal_strength", name: "Signal Strength", icon: "antenna.radiowaves.left.and.right", description: "Analyze cellular RSRP, RSRQ and SINR metrics", category: .connectivity),
        DiagnosticTool(id: "5g_status", name: "5G Availability", icon: "5.circle.fill", description: "Detect 5G Standalone and Non-Standalone support", category: .connectivity),
        DiagnosticTool(id: "public_ip", name: "Public IP", icon: "globe", description: "View public IP, ISP and geolocation data", category: .connectivity),
        DiagnosticTool(id: "local_network", name: "Local Network", icon: "network", description: "Scan and identify devices on the local network", category: .connectivity),
        DiagnosticTool(id: "proxy_check", name: "Proxy & Tunnel", icon: "shield.lefthalf.filled", description: "Detect active proxies and network tunnels", category: .connectivity),

        // Performance Expanded (6)
        DiagnosticTool(id: "packet_loss", name: "Packet Loss", icon: "exclamationmark.icloud.fill", description: "Measure network packet loss and jitter", category: .performance),
        DiagnosticTool(id: "kernel_info", name: "Kernel Info", icon: "terminal.fill", description: "Detailed XNU kernel version and build metrics", category: .performance),
        DiagnosticTool(id: "ram_latency", name: "RAM Latency", icon: "memorychip.fill", description: "Benchmark memory access latency and bandwidth", category: .performance),
        DiagnosticTool(id: "thermal_throttling", name: "Thermal Throttling", icon: "thermometer.sun.fill", description: "Monitor CPU frequency scaling due to heat", category: .performance),
        DiagnosticTool(id: "cpu_freq", name: "CPU Frequency", icon: "bolt.horizontal.fill", description: "Real-time CPU clock frequency monitoring", category: .performance),
        DiagnosticTool(id: "swap_usage", name: "Swap Usage", icon: "arrow.left.and.right.square", description: "Monitor system swap file activity and size", category: .performance),

        // System Expanded (5)
        DiagnosticTool(id: "interrupts", name: "System Interrupts", icon: "waveform.path.ecg", description: "Monitor hardware interrupts and context switches", category: .system),
        DiagnosticTool(id: "power_metrics", name: "Power Metrics", icon: "bolt.batteryblock.fill", description: "Detailed power consumption and energy impact", category: .system),
        DiagnosticTool(id: "entitlements", name: "App Entitlements", icon: "key.fill", description: "Verify active app capabilities and sandbox rules", category: .system),
        DiagnosticTool(id: "sandbox_check", name: "Sandbox Audit", icon: "shippingbox.fill", description: "Check sandbox restrictions and file access", category: .system),
        DiagnosticTool(id: "fs_speed", name: "File System Speed", icon: "doc.badge.gearshape.fill", description: "Benchmark sequential and random I/O performance", category: .system),

        // Hardware (5)
        DiagnosticTool(id: "oled_check", name: "OLED Uniformity", icon: "rectangle.inset.filled", description: "Test for OLED burn-in and color shifting", category: .display),
        DiagnosticTool(id: "audio_sweep", name: "Frequency Sweep", icon: "waveform", description: "Play 20Hz - 20kHz sweep to test speaker range", category: .audio),
        DiagnosticTool(id: "lidar_mesh", name: "LiDAR Mesh", icon: "dot.radiowaves.up.forward", description: "Visualize real-time 3D room reconstruction", category: .camera),
        DiagnosticTool(id: "truedepth_points", name: "TrueDepth Cloud", icon: "faceid", description: "View raw point cloud from TrueDepth sensor", category: .camera),
        DiagnosticTool(id: "nfc_data", name: "NFC Field Data", icon: "wave.3.right.circle", description: "Monitor NFC field strength and tech types", category: .connectivity),

        // Security (5)
        DiagnosticTool(id: "secure_element", name: "Secure Element", icon: "cpu.fill", description: "Verify Apple Pay Secure Element status", category: .security),
        DiagnosticTool(id: "device_identity", name: "Device Identity", icon: "person.badge.shield.check.fill", description: "Check DeviceCheck and App Attest tokens", category: .security),
        DiagnosticTool(id: "cert_check", name: "Certificate Trust", icon: "checkmark.seal.fill", description: "Audit system and user-installed certificates", category: .security),
        DiagnosticTool(id: "screen_res", name: "Screen Resolution", icon: "aspectratio.fill", description: "Verify native resolution and points density", category: .display),
        DiagnosticTool(id: "taptic_fidelity", name: "Taptic Fidelity", icon: "waveform.path", description: "Test Taptic Engine precision and latency", category: .haptics),
        DiagnosticTool(id: "camera_metadata", name: "Camera Metadata", icon: "info.circle.fill", description: "View detailed lens and sensor EXIF capabilities", category: .camera),
    ]

    var filteredTools: [DiagnosticTool] {
        var result = allTools
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.description.lowercased().contains(query) ||
                $0.category.rawValue.lowercased().contains(query)
            }
        }
        return result
    }

    var toolsByCategory: [(DiagnosticCategory, [DiagnosticTool])] {
        let tools = filteredTools
        var result: [(DiagnosticCategory, [DiagnosticTool])] = []
        for category in DiagnosticCategory.allCases {
            let categoryTools = tools.filter { $0.category == category }
            if !categoryTools.isEmpty {
                result.append((category, categoryTools))
            }
        }
        return result
    }

    var totalToolCount: Int { allTools.count }
}
