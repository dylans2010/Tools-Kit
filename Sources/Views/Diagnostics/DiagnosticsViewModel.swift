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
        }
    }
}

@MainActor
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

        // === NEW DIAGNOSTIC TOOLS (28) ===

        // GPS & Location
        DiagnosticTool(id: "gps_location", name: "GPS Location", icon: "location.fill", description: "Real-time GPS coordinates, altitude, speed via CoreLocation", category: .sensors),
        DiagnosticTool(id: "satellite_connectivity", name: "Satellite Connectivity", icon: "satellite.fill", description: "iPhone 14+ satellite hardware detection and network fallback", category: .connectivity),
        DiagnosticTool(id: "compass_heading", name: "Compass Heading", icon: "location.north.fill", description: "Magnetic and true heading with raw field data", category: .sensors),
        DiagnosticTool(id: "altimeter", name: "Altimeter", icon: "mountain.2.fill", description: "Barometric altitude and atmospheric pressure tracking", category: .sensors),
        DiagnosticTool(id: "location_history", name: "Location History", icon: "map.fill", description: "Track location path, distance, and movement history", category: .sensors),
        DiagnosticTool(id: "device_orientation", name: "Device Orientation", icon: "rotate.3d", description: "Real-time pitch, roll, yaw with gravity vector", category: .sensors),
        DiagnosticTool(id: "motion_sensor_fusion", name: "Motion Sensor Fusion", icon: "gyroscope", description: "Combined accelerometer, gyro, magnetometer fusion data", category: .sensors),

        // Networking
        DiagnosticTool(id: "dns_lookup", name: "DNS Lookup", icon: "server.rack", description: "Real DNS resolution with IPv4/IPv6 address discovery", category: .connectivity),
        DiagnosticTool(id: "port_scanner", name: "Port Scanner", icon: "network.badge.shield.half.filled", description: "TCP port scanning with concurrent connection testing", category: .connectivity),
        DiagnosticTool(id: "traceroute", name: "Traceroute", icon: "point.3.connected.trianglepath.dotted", description: "Network path tracing with hop-by-hop RTT analysis", category: .connectivity),
        DiagnosticTool(id: "bandwidth_monitor", name: "Bandwidth Monitor", icon: "chart.line.uptrend.xyaxis", description: "Real-time network throughput from interface statistics", category: .connectivity),
        DiagnosticTool(id: "socket_test", name: "Socket Test", icon: "cable.connector", description: "TCP/TLS connection testing with endpoint inspection", category: .connectivity),
        DiagnosticTool(id: "ssl_certificate", name: "SSL Certificate", icon: "lock.doc.fill", description: "SSL/TLS certificate inspection and validation", category: .connectivity),
        DiagnosticTool(id: "wifi_analyzer", name: "WiFi Analyzer", icon: "wifi.circle.fill", description: "WiFi network details, signal, and interface statistics", category: .connectivity),
        DiagnosticTool(id: "network_proxy", name: "Network Proxy", icon: "shield.lefthalf.filled", description: "Proxy settings, VPN detection, and DNS configuration", category: .connectivity),
        DiagnosticTool(id: "network_interfaces", name: "Network Interfaces", icon: "network", description: "All network interfaces with addresses and traffic stats", category: .connectivity),
        DiagnosticTool(id: "ping_tool", name: "Ping Tool", icon: "waveform.path.ecg", description: "ICMP-style reachability test with RTT statistics", category: .connectivity),
        DiagnosticTool(id: "http_headers", name: "HTTP Headers", icon: "doc.text.magnifyingglass", description: "Inspect HTTP request and response headers", category: .connectivity),
        DiagnosticTool(id: "cellular_detail", name: "Cellular Detail", icon: "antenna.radiowaves.left.and.right.circle.fill", description: "Carrier info, radio technology, SIM, and data usage", category: .connectivity),

        // System
        DiagnosticTool(id: "system_load", name: "System Load", icon: "cpu", description: "Real-time CPU usage with per-thread monitoring", category: .performance),
        DiagnosticTool(id: "thread_count", name: "Thread Count", icon: "square.stack.3d.up.fill", description: "Active threads with state, CPU usage, and run times", category: .performance),
        DiagnosticTool(id: "memory_pressure", name: "Memory Pressure", icon: "memorychip.fill", description: "System and app memory with pressure monitoring", category: .performance),
        DiagnosticTool(id: "disk_io_benchmark", name: "Disk I/O Benchmark", icon: "gauge.with.dots.needle.bottom.50percent", description: "Sequential read/write speed benchmarking", category: .storage),
        DiagnosticTool(id: "frame_drop", name: "Frame Drop Monitor", icon: "film.stack", description: "Real-time FPS tracking with drop detection", category: .performance),
        DiagnosticTool(id: "energy_impact", name: "Energy Impact", icon: "leaf.fill", description: "Estimated energy consumption breakdown", category: .battery),
        DiagnosticTool(id: "time_sync", name: "Time Sync", icon: "clock.badge.checkmark.fill", description: "NTP time synchronization check with offset analysis", category: .system),
        DiagnosticTool(id: "kernel_info", name: "Kernel Info", icon: "terminal.fill", description: "Darwin kernel, CPU architecture, sysctl parameters", category: .system),
        DiagnosticTool(id: "runtime_info", name: "Runtime Info", icon: "swift", description: "Swift runtime, loaded libraries, process details", category: .system),
        DiagnosticTool(id: "locale_timezone", name: "Locale & Timezone", icon: "globe.americas.fill", description: "Full locale, timezone, formatting, and language details", category: .system),
        DiagnosticTool(id: "installed_fonts", name: "Installed Fonts", icon: "textformat", description: "Browse all installed font families with previews", category: .system),
        DiagnosticTool(id: "display_info", name: "Display Info", icon: "rectangle.inset.filled", description: "Resolution, refresh rate, color space, safe areas", category: .display),
        DiagnosticTool(id: "screen_mirror_detect", name: "Screen Mirror Detection", icon: "tv.and.mediabox", description: "External display and screen recording detection", category: .display),
        DiagnosticTool(id: "url_scheme_test", name: "URL Scheme Tester", icon: "link.circle.fill", description: "Test URL scheme availability for installed apps", category: .system),
        DiagnosticTool(id: "device_capabilities", name: "Device Capabilities", icon: "checklist", description: "Hardware capability audit: LiDAR, NFC, UWB, etc.", category: .system),
        DiagnosticTool(id: "battery_cycle", name: "Battery Cycle", icon: "battery.100.circle.fill", description: "Battery drain rate estimation and usage tracking", category: .battery),
        DiagnosticTool(id: "crash_log", name: "Crash Log", icon: "ant.fill", description: "App stability metrics and crash diagnostic data", category: .system),
        DiagnosticTool(id: "system_log", name: "System Log", icon: "doc.text.fill", description: "Live system log entries with level filtering", category: .system),
        DiagnosticTool(id: "keychain_diag", name: "Keychain Diagnostics", icon: "key.icloud.fill", description: "Keychain CRUD testing and biometric status", category: .security),
        DiagnosticTool(id: "notification_status", name: "Notification Diagnostics", icon: "bell.badge.circle.fill", description: "Push notification authorization and settings audit", category: .system),

        // === REPAIR SHOP & ADVANCED DIAGNOSTICS (51) ===

        // IMEI & Device Identity
        DiagnosticTool(id: "imei_info", name: "IMEI Info", icon: "number.circle.fill", description: "IMEI validation, structure breakdown, and device identifiers", category: .security),
        DiagnosticTool(id: "device_authenticity", name: "Device Authenticity", icon: "checkmark.seal.fill", description: "Verify genuine Apple hardware via GPU, CPU, Secure Enclave checks", category: .security),
        DiagnosticTool(id: "ios_version_detail", name: "iOS Version Detail", icon: "apple.logo", description: "Detailed OS version, kernel, build info and feature support", category: .system),

        // MDM & Enterprise
        DiagnosticTool(id: "mdm_detection", name: "MDM Detection", icon: "building.2.fill", description: "Detect Mobile Device Management profiles and supervision", category: .security),
        DiagnosticTool(id: "dep_enrollment", name: "DEP Enrollment", icon: "building.2.crop.circle.fill", description: "Check Device Enrollment Program and Apple Business Manager status", category: .security),
        DiagnosticTool(id: "enterprise_app", name: "Enterprise App Check", icon: "building.columns.fill", description: "Detect enterprise management, supervision, and MDM certificates", category: .security),
        DiagnosticTool(id: "config_profile_audit", name: "Config Profile Audit", icon: "doc.badge.gearshape", description: "Scan for MDM, VPN, certificate, and restriction profiles", category: .security),
        DiagnosticTool(id: "provisioning_profile", name: "Provisioning Profiles", icon: "doc.fill", description: "View provisioning profiles, entitlements, and code signing info", category: .security),
        DiagnosticTool(id: "restrictions_check", name: "Restrictions Check", icon: "hand.raised.circle.fill", description: "Scan for device restrictions, Screen Time, and MDM limitations", category: .security),

        // Lock & Activation
        DiagnosticTool(id: "find_my_status", name: "Find My Status", icon: "location.circle.fill", description: "Check Find My iPhone status and activation lock indicators", category: .security),
        DiagnosticTool(id: "blacklist_check", name: "Blacklist Check", icon: "exclamationmark.shield.fill", description: "IMEI blacklist/stolen device check via external API", category: .security),
        DiagnosticTool(id: "carrier_lock", name: "Carrier Lock", icon: "lock.circle.fill", description: "Detect carrier lock status, SIM info, and unlock eligibility", category: .connectivity),
        DiagnosticTool(id: "icloud_lock", name: "iCloud Lock", icon: "icloud.fill", description: "Check iCloud account indicators and activation lock status", category: .security),
        DiagnosticTool(id: "stolen_device", name: "Stolen Device Check", icon: "exclamationmark.triangle.fill", description: "Check Stolen Device Protection and theft indicators", category: .security),
        DiagnosticTool(id: "warranty_check", name: "Warranty Check", icon: "shield.fill", description: "Estimate device age and check warranty/AppleCare status", category: .system),

        // Repair Shop Tools
        DiagnosticTool(id: "full_device_report", name: "Full Device Report", icon: "doc.richtext.fill", description: "Generate comprehensive exportable device diagnostic report", category: .system),
        DiagnosticTool(id: "device_grading", name: "Device Grading", icon: "star.circle.fill", description: "Grade device condition A-F based on hardware component tests", category: .system),
        DiagnosticTool(id: "pre_repair_checklist", name: "Pre-Repair Checklist", icon: "checklist.checked", description: "Run all hardware checks before repair for documentation", category: .system),
        DiagnosticTool(id: "screen_replacement", name: "Screen Replacement Check", icon: "display", description: "Detect non-original display via resolution, scale, and refresh rate", category: .display),
        DiagnosticTool(id: "battery_replacement", name: "Battery Replacement Check", icon: "battery.100.circle", description: "Detect non-original battery via charging behavior analysis", category: .battery),
        DiagnosticTool(id: "water_damage", name: "Water Damage Check", icon: "drop.fill", description: "Software-based water damage assessment via sensor checks", category: .sensors),

        // Hardware Tests
        DiagnosticTool(id: "wireless_charging", name: "Wireless Charging", icon: "bolt.circle.fill", description: "Test wireless/MagSafe charging with live monitoring", category: .battery),
        DiagnosticTool(id: "charging_diagnostics", name: "Charging Port Diagnostics", icon: "powerplug.fill", description: "Monitor charging speed, port function, and charge rate", category: .battery),
        DiagnosticTool(id: "force_touch", name: "Force Touch Test", icon: "hand.point.up.left.fill", description: "Test 3D Touch pressure sensitivity and Haptic Touch", category: .display),
        DiagnosticTool(id: "face_id_diag", name: "Face ID Diagnostics", icon: "faceid", description: "TrueDepth camera system check and Face ID authentication test", category: .security),
        DiagnosticTool(id: "uwb_chip", name: "UWB Chip", icon: "dot.radiowaves.left.and.right", description: "Check U1/U2 Ultra Wideband chip and spatial awareness", category: .connectivity),
        DiagnosticTool(id: "nfc_readwrite", name: "NFC Read/Write", icon: "wave.3.right.circle.fill", description: "Read and write NFC tags with NDEF format support", category: .connectivity),
        DiagnosticTool(id: "lidar_scanner", name: "LiDAR Scanner", icon: "light.recessed.fill", description: "Test LiDAR depth sensor and AR scene reconstruction", category: .camera),

        // Battery & Thermal
        DiagnosticTool(id: "battery_temperature", name: "Battery Temperature", icon: "thermometer.medium", description: "Real-time thermal state monitoring with history tracking", category: .battery),
        DiagnosticTool(id: "thermal_history", name: "Thermal History", icon: "thermometer.high", description: "Thermal trend monitoring with graphing and statistics", category: .performance),
        DiagnosticTool(id: "power_source", name: "Power Source Info", icon: "powerplug.fill", description: "Power source detection, uptime, and battery monitoring", category: .battery),

        // Network & Cellular
        DiagnosticTool(id: "sim_info", name: "SIM Info", icon: "simcard.fill", description: "SIM card details, carrier info, dual SIM status", category: .connectivity),
        DiagnosticTool(id: "signal_strength", name: "Signal Strength", icon: "cellularbars", description: "Real-time cellular signal and radio technology monitor", category: .connectivity),
        DiagnosticTool(id: "esim_status", name: "eSIM Status", icon: "esim.fill", description: "Check eSIM support, active slots, and hardware compatibility", category: .connectivity),
        DiagnosticTool(id: "apn_config", name: "APN Configuration", icon: "antenna.radiowaves.left.and.right.circle.fill", description: "View carrier APN and data connection settings", category: .connectivity),
        DiagnosticTool(id: "roaming_status", name: "Roaming Status", icon: "globe.americas.fill", description: "Detect network roaming and carrier country mismatch", category: .connectivity),
        DiagnosticTool(id: "network_band", name: "Network Band", icon: "dot.radiowaves.up.forward", description: "Monitor active radio band, generation, and max speed", category: .connectivity),
        DiagnosticTool(id: "network_speed", name: "Network Speed Test", icon: "speedometer", description: "Download speed test and latency measurement", category: .connectivity),
        DiagnosticTool(id: "network_security", name: "Network Security Scan", icon: "shield.lefthalf.filled", description: "Scan for VPN, proxy, DNS security, and HTTPS verification", category: .security),

        // Security & Privacy
        DiagnosticTool(id: "certificate_trust", name: "Certificate Trust", icon: "lock.doc.fill", description: "Inspect keychain certificates and SSL trust store", category: .security),
        DiagnosticTool(id: "data_protection", name: "Data Protection", icon: "lock.rectangle.stack.fill", description: "Test iOS data protection encryption classes", category: .security),
        DiagnosticTool(id: "sandbox_integrity", name: "Sandbox Integrity", icon: "checkmark.shield.fill", description: "Verify app sandboxing and process isolation", category: .security),
        DiagnosticTool(id: "storage_encryption", name: "Storage Encryption", icon: "lock.rectangle.fill", description: "Verify device encryption, Secure Enclave, and passcode", category: .security),
        DiagnosticTool(id: "system_integrity", name: "System Integrity", icon: "shield.fill", description: "Check for jailbreak, code injection, and system tampering", category: .security),

        // System & Performance
        DiagnosticTool(id: "running_processes", name: "Running Processes", icon: "chart.bar.doc.horizontal.fill", description: "View current process details and system statistics", category: .performance),
        DiagnosticTool(id: "loaded_frameworks", name: "Loaded Frameworks", icon: "shippingbox.fill", description: "List all dynamically loaded frameworks and libraries", category: .system),
        DiagnosticTool(id: "cpu_benchmark", name: "CPU Benchmark", icon: "cpu", description: "Single and multi-core integer, float, and memory benchmarks", category: .performance),
        DiagnosticTool(id: "gpu_benchmark", name: "GPU Benchmark", icon: "gpu", description: "Metal GPU throughput benchmark with buffer operations", category: .performance),
        DiagnosticTool(id: "memory_monitor", name: "Memory Monitor", icon: "memorychip.fill", description: "Real-time app memory usage with trend graphing", category: .performance),

        // Storage & Data
        DiagnosticTool(id: "storage_usage", name: "Storage Usage", icon: "chart.pie.fill", description: "Detailed storage usage with directory breakdown", category: .storage),
        DiagnosticTool(id: "backup_status", name: "Backup Status", icon: "icloud.fill", description: "Check iCloud backup indicators and storage status", category: .system),
        DiagnosticTool(id: "crash_log_analyzer", name: "Crash Log Analyzer", icon: "exclamationmark.triangle.fill", description: "Scan for crash reports and diagnostic logs", category: .system),
        DiagnosticTool(id: "locale_tz_detail", name: "Locale & Time Zone", icon: "globe", description: "Full locale, currency, calendar, and timezone details", category: .system),

        // New IMEI & Security Tools
        DiagnosticTool(id: "imei_network_check", name: "IMEI Network Check", icon: "globe.americas.fill", description: "Identify original network, country, and carrier via IMEI API", category: .security),
        DiagnosticTool(id: "imei_device_lookup", name: "IMEI Device Lookup", icon: "iphone.gen3.circle.fill", description: "Full device specifications from IMEI via live API", category: .security),
        DiagnosticTool(id: "imei_batch_checker", name: "Batch IMEI Checker", icon: "list.clipboard.fill", description: "Check multiple IMEIs at once for blacklist and lock status", category: .security),
        DiagnosticTool(id: "imei_comprehensive", name: "Comprehensive IMEI Check", icon: "doc.text.magnifyingglass", description: "Run all IMEI checks at once: blacklist, lock, warranty, iCloud", category: .security),
        DiagnosticTool(id: "imei_carrier_compat", name: "Carrier Compatibility", icon: "simcard.2.fill", description: "Check band compatibility with major carriers worldwide", category: .connectivity),
        DiagnosticTool(id: "device_valuation", name: "Device Valuation", icon: "dollarsign.circle.fill", description: "Estimate device trade-in value based on hardware condition", category: .system),

        // === NEW HARDWARE DIAGNOSTIC TOOLS ===
        DiagnosticTool(id: "network_throughput", name: "Network Throughput", icon: "arrow.up.arrow.down.circle.fill", description: "Full download/upload speed test with latency, jitter, and packet loss", category: .connectivity),
        DiagnosticTool(id: "touch_latency", name: "Touch Latency", icon: "hand.tap.fill", description: "Measure touch screen reaction time and tap accuracy", category: .display),
        DiagnosticTool(id: "screen_burn_in", name: "Screen Burn-In", icon: "rectangle.inset.filled.and.person.filled", description: "OLED burn-in detection with solid color and pattern tests", category: .display),
        DiagnosticTool(id: "ram_stress", name: "RAM Stress Test", icon: "memorychip.fill", description: "Memory allocation stress test with write/read speed benchmarks", category: .performance),
        DiagnosticTool(id: "vibration_motor", name: "Vibration Motor", icon: "iphone.radiowaves.left.and.right", description: "Full Taptic Engine diagnostic with custom haptic patterns", category: .haptics),
        DiagnosticTool(id: "speaker_frequency", name: "Speaker Frequency", icon: "waveform.badge.mic", description: "Tone generator and frequency sweep for speaker testing", category: .audio),
        DiagnosticTool(id: "mic_quality", name: "Microphone Quality", icon: "mic.badge.plus", description: "Mic quality analysis with SNR, noise floor, and clipping detection", category: .microphone),
        DiagnosticTool(id: "impact_detection", name: "Impact Detection", icon: "waveform.badge.magnifyingglass", description: "Ambient sound monitoring for glass break and impact events", category: .sensors),
        DiagnosticTool(id: "proximity_stress", name: "Proximity Stress", icon: "hand.raised.circle.fill", description: "Proximity sensor stress test with response time tracking", category: .sensors),
        DiagnosticTool(id: "gravity_sensor", name: "Gravity Sensor", icon: "arrow.down.to.line.circle.fill", description: "Real-time gravity vector visualization with tilt and calibration", category: .sensors),
        DiagnosticTool(id: "app_resource_monitor", name: "App Resource Monitor", icon: "chart.bar.xaxis", description: "Live CPU, memory, threads, disk I/O, and process monitoring", category: .performance),

        // === EXPANDED HARDWARE DIAGNOSTICS (35) ===

        // Audio & Speaker
        DiagnosticTool(id: "earpiece_test", name: "Earpiece Test", icon: "ear.fill", description: "Test built-in earpiece receiver with tone generation", category: .audio),
        DiagnosticTool(id: "stereo_speaker_test", name: "Stereo Speaker Test", icon: "hifispeaker.2.fill", description: "Independent left/right stereo speaker testing", category: .audio),

        // Camera System
        DiagnosticTool(id: "camera_control", name: "Camera Control", icon: "camera.shutter.button.fill", description: "iPhone 16+ Camera Control button detection and features", category: .camera),
        DiagnosticTool(id: "telephoto_lens", name: "Telephoto Lens", icon: "camera.aperture", description: "Test telephoto camera with optical zoom and preview", category: .camera),
        DiagnosticTool(id: "ultra_wide_lens", name: "Ultra Wide Lens", icon: "camera.aperture", description: "0.5x ultra wide-angle camera with 120° field of view", category: .camera),
        DiagnosticTool(id: "macro_camera", name: "Macro Camera", icon: "leaf.fill", description: "Close-up macro photography via ultra wide with autofocus", category: .camera),
        DiagnosticTool(id: "wide_lens", name: "Wide Lens", icon: "camera.fill", description: "Primary 1x wide-angle camera diagnostics and preview", category: .camera),
        DiagnosticTool(id: "infrared_camera", name: "Infrared Camera", icon: "camera.filters", description: "TrueDepth infrared emitter, dot projector, and IR sensor", category: .camera),
        DiagnosticTool(id: "lidar_full", name: "LiDAR Full", icon: "light.recessed.fill", description: "Full LiDAR: depth mapping, mesh reconstruction, measurement", category: .camera),
        DiagnosticTool(id: "depth_sensor", name: "Depth Sensor", icon: "cube.transparent.fill", description: "TrueDepth, LiDAR, and dual-camera depth capabilities", category: .camera),
        DiagnosticTool(id: "cinematic_mode", name: "Cinematic Mode", icon: "video.fill", description: "Rack focus video with depth-of-field and focus transitions", category: .camera),
        DiagnosticTool(id: "proraw_prores", name: "ProRAW & ProRes", icon: "camera.badge.ellipsis.fill", description: "Apple ProRAW photography and ProRes video capabilities", category: .camera),
        DiagnosticTool(id: "night_mode", name: "Night Mode", icon: "moon.stars.fill", description: "Low-light multi-frame photography and long exposure", category: .camera),
        DiagnosticTool(id: "portrait_mode", name: "Portrait Mode", icon: "person.crop.square.fill", description: "Depth-based bokeh for photo and video", category: .camera),
        DiagnosticTool(id: "autofocus_test", name: "Autofocus Test", icon: "camera.metering.center.weighted", description: "Camera autofocus, continuous AF, and tap-to-focus test", category: .camera),
        DiagnosticTool(id: "ois_test", name: "OIS Test", icon: "hand.raised.slash.fill", description: "Optical and sensor-shift image stabilization test", category: .camera),
        DiagnosticTool(id: "photonic_engine", name: "Photonic Engine", icon: "cpu.fill", description: "Advanced computational photography pipeline check", category: .camera),
        DiagnosticTool(id: "true_tone_flash", name: "True Tone Flash", icon: "bolt.circle.fill", description: "Adaptive True Tone LED flash with color temperature matching", category: .camera),

        // Buttons & Hardware
        DiagnosticTool(id: "mute_switch_action", name: "Mute Switch / Action Button", icon: "button.horizontal.top.press.fill", description: "Ring/Silent toggle or Action Button (iPhone 15 Pro+) test", category: .system),
        DiagnosticTool(id: "volume_buttons", name: "Volume Buttons", icon: "speaker.wave.2.fill", description: "Volume Up/Down button detection with press history", category: .system),
        DiagnosticTool(id: "action_button", name: "Action Button", icon: "button.horizontal.top.press.fill", description: "iPhone 15 Pro+ customizable Action Button check", category: .system),
        DiagnosticTool(id: "side_button", name: "Side Button", icon: "power.circle.fill", description: "Side/Power button test with screenshot detection", category: .system),

        // Touch & Display
        DiagnosticTool(id: "digitizer_test", name: "Digitizer Test", icon: "hand.draw.fill", description: "Touch screen digitizer zone coverage and dead spot detection", category: .display),
        DiagnosticTool(id: "always_on_display", name: "Always On Display", icon: "display", description: "LTPO OLED Always On Display detection and info", category: .display),
        DiagnosticTool(id: "promotion_test", name: "ProMotion Test", icon: "gauge.with.dots.needle.100percent", description: "120Hz ProMotion display with live FPS monitoring", category: .display),
        DiagnosticTool(id: "dynamic_island", name: "Dynamic Island", icon: "pill.circle.fill", description: "Interactive pill-shaped display cutout detection", category: .display),

        // NFC Advanced
        DiagnosticTool(id: "nfc_diagnostics", name: "NFC Diagnostics", icon: "wave.3.right.circle.fill", description: "Advanced NFC: NDEF, ISO 14443, MIFARE, FeliCa protocols", category: .connectivity),

        // Connectivity & Wireless
        DiagnosticTool(id: "wifi_6e", name: "WiFi 6E / WiFi 7", icon: "wifi.circle.fill", description: "6 GHz WiFi band support and WiFi 7 detection", category: .connectivity),
        DiagnosticTool(id: "five_g_band", name: "5G Band", icon: "antenna.radiowaves.left.and.right.circle.fill", description: "Sub-6 GHz and mmWave 5G connectivity diagnostics", category: .connectivity),
        DiagnosticTool(id: "wireless_antenna", name: "Wireless Antenna", icon: "antenna.radiowaves.left.and.right", description: "WiFi, Cellular, Bluetooth, GPS, NFC, UWB antenna systems", category: .connectivity),
        DiagnosticTool(id: "thread_radio", name: "Thread Radio", icon: "circle.grid.cross.fill", description: "Thread/Matter smart home mesh networking radio", category: .connectivity),

        // Sensors & Safety
        DiagnosticTool(id: "magsafe_test", name: "MagSafe Test", icon: "magsafe.batterypack.fill", description: "MagSafe magnetic alignment with magnetometer monitoring", category: .sensors),
        DiagnosticTool(id: "crash_detection", name: "Crash Detection", icon: "car.side.front.open.fill", description: "Severe car crash detection sensor and feature check", category: .sensors),
        DiagnosticTool(id: "gps_accuracy", name: "GPS Accuracy", icon: "location.fill", description: "Real-time GPS accuracy with horizontal/vertical precision", category: .sensors),

        // Safety & Features
        DiagnosticTool(id: "emergency_sos", name: "Emergency SOS Satellite", icon: "sos.circle.fill", description: "Contact emergency services via satellite when offline", category: .connectivity),

        // Haptics
        DiagnosticTool(id: "haptic_intensity", name: "Haptic Intensity", icon: "hand.tap.fill", description: "Custom intensity/sharpness haptic testing with presets", category: .haptics),

        // Power
        DiagnosticTool(id: "power_delivery", name: "Power Delivery", icon: "powerplug.fill", description: "USB-C/Lightning charging speed and power delivery monitor", category: .battery),
        DiagnosticTool(id: "usbc_port", name: "USB-C Port", icon: "cable.connector", description: "USB-C port diagnostics, speed tier, and DisplayPort", category: .system),

        // Biometrics
        DiagnosticTool(id: "face_id_test", name: "Face ID Test", icon: "faceid", description: "Face ID enrollment check and authentication test", category: .security),
        DiagnosticTool(id: "touch_id_test", name: "Touch ID Test", icon: "touchid", description: "Touch ID fingerprint sensor test and authentication", category: .security),

        // Microphone
        DiagnosticTool(id: "microphone_array", name: "Microphone Array", icon: "mic.fill", description: "All built-in microphones, beamforming, and positions", category: .microphone),

        // === DEEPER DIAGNOSTICS (10) ===
        DiagnosticTool(id: "privacy_report", name: "App Privacy Report", icon: "hand.raised.square.on.square.fill", description: "Audit app access to photos, location, and sensors", category: .security),
        DiagnosticTool(id: "metal_capability", name: "Metal Capabilities", icon: "cpu.fill", description: "Detailed GPU architecture and feature support", category: .performance),
        DiagnosticTool(id: "cpu_topology", name: "CPU Topology", icon: "cpu", description: "View P-cores and E-cores load and layout", category: .performance),
        DiagnosticTool(id: "disk_leak", name: "Disk Space Leak", icon: "internaldrive.fill", description: "Find hidden storage consumers and temporary files", category: .storage),
        DiagnosticTool(id: "bt_packet", name: "BT Packet Monitor", icon: "wave.3.right.circle", description: "Simulated Bluetooth packet traffic analysis", category: .connectivity),
        DiagnosticTool(id: "adv_traceroute", name: "Advanced TraceRoute", icon: "point.3.connected.trianglepath.dotted", description: "Detailed hop-by-hop network path analysis", category: .connectivity),
        DiagnosticTool(id: "memory_map", name: "Memory Mapping", icon: "memorychip", description: "View virtual memory regions and protections", category: .performance),
        DiagnosticTool(id: "sensor_drift", name: "Sensor Drift Analysis", icon: "sensor", description: "Check calibration and drift for all motion sensors", category: .sensors),
        DiagnosticTool(id: "white_point", name: "White Point Test", icon: "sun.max.circle", description: "Verify D65 calibration and color temperature", category: .display),
        DiagnosticTool(id: "audio_phase", name: "Audio Phase Test", icon: "waveform.path", description: "Check phase correlation between stereo speakers", category: .audio),
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
