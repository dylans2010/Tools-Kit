import SwiftUI

struct DiagnosticsHomeView: View {
    @StateObject private var viewModel = DiagnosticsViewModel()
    @StateObject private var diagnosticsMode = DiagnosticsModeManager.shared
    @State private var showSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    categoryScrollBar
                    toolsGrid
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .searchable(text: $viewModel.searchText, prompt: "Search \(viewModel.totalToolCount) diagnostic tools")
            .navigationTitle("Diagnostics")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        diagnosticsMode.isDiagnosticsModeEnabled = false
                    } label: {
                        Image(systemName: "arrow.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                AIChatSettingsView(settings: .constant(AIChatSettings()))
            }
        }
    }

    private var categoryScrollBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                DiagnosticsCategoryChip(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: viewModel.selectedCategory == nil,
                    tint: .blue
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedCategory = nil
                    }
                }

                ForEach(DiagnosticCategory.allCases) { category in
                    DiagnosticsCategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category,
                        tint: category.tint
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedCategory = (viewModel.selectedCategory == category) ? nil : category
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var toolsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.filteredTools) { tool in
                NavigationLink(destination: diagnosticDestination(for: tool)) {
                    DiagnosticsToolCardView(tool: tool)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func diagnosticDestination(for tool: DiagnosticTool) -> some View {
        switch tool.id {
        // Display
        case "screen_color": Diag_ScreenColorTestView()
        case "dead_pixel": Diag_DeadPixelDetectionView()
        case "brightness": Diag_BrightnessTestView()
        case "touch_response": Diag_TouchResponsivenessView()
        case "multi_touch": Diag_MultiTouchTrackingView()
        case "true_tone": Diag_TrueToneCheckView()
        case "color_accuracy": Diag_ColorAccuracyView()
        // Audio
        case "speaker_test": Diag_SpeakerTestView()
        case "stereo_balance": Diag_StereoBalanceView()
        case "volume_ramp": Diag_VolumeRampView()
        case "distortion": Diag_DistortionDetectionView()
        case "audio_latency": Diag_AudioLatencyView()
        // Microphone
        case "mic_level": Diag_MicInputLevelView()
        case "noise_detect": Diag_NoiseDetectionView()
        case "recording_test": Diag_RecordingTestView()
        case "mic_switch": Diag_MultiMicSwitchingView()
        // Sensors
        case "accelerometer": Diag_AccelerometerView()
        case "gyroscope": Diag_GyroscopeView()
        case "magnetometer": Diag_MagnetometerView()
        case "proximity": Diag_ProximitySensorView()
        case "ambient_light": Diag_AmbientLightView()
        // Haptics
        case "haptic_test": Diag_HapticFeedbackView()
        case "haptic_pattern": Diag_PatternPlaybackView()
        case "taptic_engine": Diag_TapticEngineView()
        // Connectivity
        case "wifi_strength": Diag_WiFiStrengthView()
        case "network_latency": Diag_NetworkLatencyView()
        case "internet_speed": Diag_InternetSpeedView()
        case "bluetooth": Diag_BluetoothScannerView()
        case "airplane": Diag_AirplaneModeView()
        // Performance
        case "cpu_stress": Diag_CPUStressTestView()
        case "memory_usage": Diag_MemoryUsageView()
        case "fps_monitor": Diag_FPSMonitorView()
        case "thermal_state": Diag_ThermalStateView()
        case "process_info": Diag_ProcessInfoView()
        // Battery
        case "battery_level": Diag_BatteryHealthView()
        case "charging_state": Diag_ChargingStateView()
        case "battery_drain": Diag_BatteryDrainSimView()
        // Camera
        case "front_camera": Diag_FrontCameraView()
        case "rear_camera": Diag_RearCameraView()
        case "focus_test": Diag_FocusTestView()
        case "flash_test": Diag_FlashTestView()
        // Storage
        case "disk_usage": Diag_DiskUsageView()
        case "rw_test": Diag_ReadWriteTestView()
        case "file_system": Diag_FileSystemInfoView()
        // System
        case "device_info": Diag_DeviceInfoView()
        case "uptime": Diag_UptimeView()
        case "permissions": Diag_PermissionsCheckerView()
        case "locale_info": Diag_LocaleInfoView()
        case "notifications": Diag_NotificationStatusView()
        // Accessibility
        case "voiceover": Diag_VoiceOverStatusView()
        case "dynamic_type": Diag_DynamicTypeView()
        case "reduce_motion": Diag_ReduceMotionView()
        // Security
        case "biometric": Diag_BiometricCheckView()
        case "passcode": Diag_PasscodeStatusView()
        case "secure_enclave": Diag_SecureEnclaveView()
        default:
            Text("Tool not found")
        }
    }
}

struct DiagnosticsCategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? tint : Color(.tertiarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}
