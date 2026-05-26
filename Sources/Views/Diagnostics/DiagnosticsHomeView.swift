import SwiftUI

struct DiagnosticsHomeView: View {
    @StateObject private var viewModel = DiagnosticsViewModel()
    @StateObject private var diagnosticsMode = DiagnosticsModeManager.shared
    @State private var showSettings = false
    @State private var showSupportAssist = false

    @AppStorage("diagnostics_enableAIAssist") private var enableAIAssist = true

    var body: some View {
        NavigationStack {
            List {
                headerSection
                categoryScrollBar
                toolsList
            }
            .listStyle(.insetGrouped)
            .searchable(text: $viewModel.searchText, prompt: "Search \(viewModel.totalToolCount) diagnostic tools")
            .navigationTitle("Diagnostics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if enableAIAssist {
                            Button {
                                showSupportAssist = true
                            } label: {
                                Image(systemName: "sparkles.rectangle.stack")
                            }
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showSupportAssist) {
                DiagnosticsSupportAssistView()
            }
            .fullScreenCover(isPresented: $showSettings) {
                DiagnosticsHomeSettingsView()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.totalToolCount) Diagnostic Tools")
                .font(.headline)
            Text("Select a category to filter or search for a specific hardware test.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var categoryScrollBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                DiagnosticsCategoryChip(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedCategory = nil
                    }
                }

                ForEach(DiagnosticCategory.allCases) { category in
                    DiagnosticsCategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category
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

    private var toolsList: some View {
        ForEach(viewModel.toolsByCategory, id: \.0) { category, tools in
            Section {
                ForEach(tools) { tool in
                    NavigationLink(destination: diagnosticDestination(for: tool)) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(tool.category.tint.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                Image(systemName: tool.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(tool.category.tint)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tool.name)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.primary)

                                Text(tool.description)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowSeparator(.visible)
                    .listRowBackground(Color(.secondarySystemGroupedBackground))
                }
            } header: {
                HStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .font(.caption)
                    Text(category.rawValue)
                }
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
        case "refresh_rate": Diag_RefreshRateView()
        case "hdr_display": Diag_HDRDisplayView()
        case "display_zoom": Diag_DisplayZoomView()
        // Audio
        case "speaker_test": Diag_SpeakerTestView()
        case "stereo_balance": Diag_StereoBalanceView()
        case "volume_ramp": Diag_VolumeRampView()
        case "distortion": Diag_DistortionDetectionView()
        case "audio_latency": Diag_AudioLatencyView()
        case "spatial_audio": Diag_SpatialAudioView()
        case "audio_routing": Diag_AudioRoutingView()
        // Microphone
        case "mic_level": Diag_MicInputLevelView()
        case "noise_detect": Diag_NoiseDetectionView()
        case "recording_test": Diag_RecordingTestView()
        case "mic_switch": Diag_MultiMicSwitchingView()
        case "voice_isolation": Diag_VoiceIsolationView()
        // Sensors
        case "accelerometer": Diag_AccelerometerView()
        case "gyroscope": Diag_GyroscopeView()
        case "magnetometer": Diag_MagnetometerView()
        case "proximity": Diag_ProximitySensorView()
        case "ambient_light": Diag_AmbientLightView()
        case "barometer": Diag_BarometerView()
        case "pedometer": Diag_PedometerView()
        case "motion_activity": Diag_MotionActivityView()
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
        case "cellular_info": Diag_CellularInfoView()
        case "nfc_check": Diag_NFCCheckView()
        case "vpn_status": Diag_VPNStatusView()
        case "network_info": Diag_NetworkInfoView()
        // Performance
        case "cpu_stress": Diag_CPUStressTestView()
        case "memory_usage": Diag_MemoryUsageView()
        case "fps_monitor": Diag_FPSMonitorView()
        case "thermal_state": Diag_ThermalStateView()
        case "process_info": Diag_ProcessInfoView()
        case "gpu_info": Diag_GPUInfoView()
        case "app_launch": Diag_AppLaunchTimeView()
        // Battery
        case "battery_level": Diag_BatteryHealthView()
        case "charging_state": Diag_ChargingStateView()
        case "battery_drain": Diag_BatteryDrainSimView()
        case "low_power": Diag_LowPowerModeView()
        // Camera
        case "front_camera": Diag_FrontCameraView()
        case "rear_camera": Diag_RearCameraView()
        case "focus_test": Diag_FocusTestView()
        case "flash_test": Diag_FlashTestView()
        case "zoom_range": Diag_ZoomRangeView()
        case "lidar_check": Diag_LiDARCheckView()
        case "truedepth": Diag_TrueDepthView()
        // Storage
        case "disk_usage": Diag_DiskUsageView()
        case "rw_test": Diag_ReadWriteTestView()
        case "file_system": Diag_FileSystemInfoView()
        case "cache_size": Diag_CacheSizeView()
        case "storage_health": Diag_StorageHealthView()
        // System
        case "device_info": Diag_DeviceInfoView()
        case "uptime": Diag_UptimeView()
        case "permissions": Diag_PermissionsCheckerView()
        case "locale_info": Diag_LocaleInfoView()
        case "notifications": Diag_NotificationStatusView()
        case "bg_refresh": Diag_BackgroundRefreshView()
        case "screen_time": Diag_ScreenTimeView()
        case "hw_buttons": Diag_HardwareButtonsView()
        // Accessibility
        case "voiceover": Diag_VoiceOverStatusView()
        case "dynamic_type": Diag_DynamicTypeView()
        case "reduce_motion": Diag_ReduceMotionView()
        case "bold_text": Diag_BoldTextCheckView()
        case "color_filters": Diag_ColorFiltersView()
        // Security
        case "biometric": Diag_BiometricCheckView()
        case "passcode": Diag_PasscodeStatusView()
        case "secure_enclave": Diag_SecureEnclaveView()
        case "jailbreak": Diag_JailbreakDetectionView()
        case "ats_check": Diag_ATSCheckView()
        case "keychain_check": Diag_KeychainCheckView()
        // === NEW TOOLS ===
        // GPS & Location
        case "gps_location": Diag_GPSLocationView()
        case "satellite_connectivity": Diag_SatelliteConnectivityView()
        case "compass_heading": Diag_CompassHeadingView()
        case "altimeter": Diag_AltimeterView()
        case "location_history": Diag_LocationHistoryView()
        case "device_orientation": Diag_DeviceOrientationView()
        case "motion_sensor_fusion": Diag_MotionSensorFusionView()
        // Networking
        case "dns_lookup": Diag_DNSLookupView()
        case "port_scanner": Diag_PortScannerView()
        case "traceroute": Diag_TracerouteView()
        case "bandwidth_monitor": Diag_BandwidthMonitorView()
        case "socket_test": Diag_SocketTestView()
        case "ssl_certificate": Diag_SSLCertificateView()
        case "wifi_analyzer": Diag_WiFiAnalyzerView()
        case "network_proxy": Diag_NetworkProxyView()
        case "network_interfaces": Diag_NetworkInterfacesView()
        case "ping_tool": Diag_PingToolView()
        case "http_headers": Diag_HTTPHeadersView()
        case "cellular_detail": Diag_CellularInfoView()
        // System & Performance
        case "system_load": Diag_SystemLoadView()
        case "thread_count": Diag_ThreadCountView()
        case "memory_pressure": Diag_MemoryPressureView()
        case "disk_io_benchmark": Diag_DiskIOBenchmarkView()
        case "frame_drop": Diag_FrameDropView()
        case "energy_impact": Diag_EnergyImpactView()
        case "time_sync": Diag_TimeSyncView()
        case "kernel_info": Diag_KernelInfoView()
        case "runtime_info": Diag_RuntimeInfoView()
        case "locale_timezone": Diag_LocaleTimezoneView()
        case "installed_fonts": Diag_InstalledFontsView()
        case "display_info": Diag_DisplayInfoView()
        case "screen_mirror_detect": Diag_ScreenMirrorDetectView()
        case "url_scheme_test": Diag_URLSchemeTestView()
        case "device_capabilities": Diag_DeviceCapabilitiesView()
        case "battery_cycle": Diag_BatteryCycleView()
        case "crash_log": Diag_CrashLogView()
        case "system_log": Diag_SystemLogView()
        case "keychain_diag": Diag_KeychainDiagView()
        case "notification_status": Diag_NotificationStatusView()
        // === REPAIR SHOP & ADVANCED DIAGNOSTICS ===
        // IMEI & Device Identity
        case "imei_info": Diag_IMEIInfoView()
        case "device_authenticity": Diag_DeviceAuthenticityView()
        case "ios_version_detail": Diag_IOSVersionDetailView()
        // MDM & Enterprise
        case "mdm_detection": Diag_MDMDetectionView()
        case "dep_enrollment": Diag_DEPEnrollmentView()
        case "enterprise_app": Diag_EnterpriseAppCheckView()
        case "config_profile_audit": Diag_ConfigProfileAuditView()
        case "provisioning_profile": Diag_ProvisioningProfileView()
        case "restrictions_check": Diag_RestrictionsCheckView()
        // Lock & Activation
        case "find_my_status": Diag_FindMyStatusView()
        case "blacklist_check": Diag_BlacklistCheckView()
        case "carrier_lock": Diag_CarrierLockView()
        case "icloud_lock": Diag_iCloudLockView()
        case "stolen_device": Diag_StolenDeviceCheckView()
        case "warranty_check": Diag_WarrantyCheckView()
        // Repair Shop Tools
        case "full_device_report": Diag_FullDeviceReportView()
        case "device_grading": Diag_DeviceGradingView()
        case "pre_repair_checklist": Diag_PreRepairChecklistView()
        case "screen_replacement": Diag_ScreenReplacementCheckView()
        case "battery_replacement": Diag_BatteryReplacementCheckView()
        case "water_damage": Diag_WaterDamageCheckView()
        // Hardware Tests
        case "wireless_charging": Diag_WirelessChargingView()
        case "charging_diagnostics": Diag_ChargingDiagnosticsView()
        case "force_touch": Diag_ForceTouchTestView()
        case "face_id_diag": Diag_FaceIDDiagnosticsView()
        case "uwb_chip": Diag_UWBChipView()
        case "nfc_readwrite": Diag_NFCReadWriteView()
        case "lidar_scanner": Diag_LiDARCheckView()
        // Battery & Thermal
        case "battery_temperature": Diag_BatteryTemperatureView()
        case "thermal_history": Diag_ThermalHistoryView()
        case "power_source": Diag_PowerSourceInfoView()
        // Network & Cellular
        case "sim_info": Diag_SIMInfoView()
        case "signal_strength": Diag_SignalStrengthView()
        case "esim_status": Diag_eSIMStatusView()
        case "apn_config": Diag_APNConfigView()
        case "roaming_status": Diag_RoamingStatusView()
        case "network_band": Diag_NetworkBandView()
        case "network_speed": Diag_NetworkSpeedTestView()
        case "network_security": Diag_NetworkSecurityScanView()
        // Security & Privacy
        case "certificate_trust": Diag_CertificateTrustView()
        case "data_protection": Diag_DataProtectionCheckView()
        case "sandbox_integrity": Diag_SandboxIntegrityView()
        case "storage_encryption": Diag_StorageEncryptionView()
        case "system_integrity": Diag_SystemIntegrityCheckView()
        // System & Performance
        case "running_processes": Diag_RunningProcessesView()
        case "loaded_frameworks": Diag_LoadedFrameworksView()
        case "cpu_benchmark": Diag_CPUBenchmarkView()
        case "gpu_benchmark": Diag_GPUBenchmarkView()
        case "memory_monitor": Diag_MemoryPressureView()
        // Storage & Data
        case "storage_usage": Diag_StorageUsageView()
        case "backup_status": Diag_BackupStatusView()
        case "crash_log_analyzer": Diag_CrashLogAnalyzerView()
        // New IMEI & Security Tools
        case "imei_network_check": Diag_IMEINetworkCheckView()
        case "imei_device_lookup": Diag_IMEIDeviceLookupView()
        case "imei_batch_checker": Diag_IMEIBatchCheckerView()
        case "imei_comprehensive": Diag_IMEIComprehensiveView()
        case "imei_carrier_compat": Diag_IMEICarrierCompatView()
        case "device_valuation": Diag_DeviceValuationView()
        // === NEW HARDWARE DIAGNOSTIC TOOLS ===
        case "network_throughput": Diag_NetworkThroughputView()
        case "touch_latency": Diag_TouchLatencyView()
        case "screen_burn_in": Diag_ScreenBurnInView()
        case "ram_stress": Diag_RAMStressTestView()
        case "vibration_motor": Diag_VibrationMotorView()
        case "speaker_frequency": Diag_SpeakerFrequencyView()
        case "mic_quality": Diag_MicrophoneQualityView()
        case "impact_detection": Diag_GlassBreakDetectView()
        case "proximity_stress": Diag_ProximityStressView()
        case "gravity_sensor": Diag_GravitySensorView()
        case "app_resource_monitor": Diag_AppResourceMonitorView()
        // === EXPANDED HARDWARE DIAGNOSTICS ===
        // Audio & Speaker
        case "earpiece_test": Diag_EarpieceTestView()
        case "stereo_speaker_test": Diag_StereoSpeakerTestView()
        // Camera System
        case "camera_control": Diag_CameraControlView()
        case "telephoto_lens": Diag_TelephotoLensView()
        case "ultra_wide_lens": Diag_UltraWideLensView()
        case "macro_camera": Diag_MacroCameraView()
        case "wide_lens": Diag_WideLensView()
        case "infrared_camera": Diag_InfraredCameraView()
        case "lidar_full": Diag_LiDARFullView()
        case "depth_sensor": Diag_DepthSensorView()
        case "cinematic_mode": Diag_CinematicModeView()
        case "proraw_prores": Diag_ProRAWProResView()
        case "night_mode": Diag_NightModeView()
        case "portrait_mode": Diag_PortraitModeView()
        case "autofocus_test": Diag_AutofocusTestView()
        case "ois_test": Diag_OISTestView()
        case "photonic_engine": Diag_PhotonicEngineView()
        case "true_tone_flash": Diag_TrueToneFlashView()
        // Buttons & Hardware
        case "mute_switch_action": Diag_MuteSwitchActionButtonView()
        case "volume_buttons": Diag_VolumeButtonsView()
        case "action_button": Diag_ActionButtonView()
        case "side_button": Diag_SideButtonView()
        // Touch & Display
        case "digitizer_test": Diag_DigitizerTestView()
        case "always_on_display": Diag_AlwaysOnDisplayView()
        case "promotion_test": Diag_ProMotionTestView()
        case "dynamic_island": Diag_DynamicIslandView()
        // NFC Advanced
        case "nfc_diagnostics": Diag_NFCDiagnosticsView()
        // Connectivity & Wireless
        case "wifi_6e": Diag_WiFi6ECheckView()
        case "five_g_band": Diag_5GBandView()
        case "wireless_antenna": Diag_WirelessAntennaView()
        case "thread_radio": Diag_ThreadRadioView()
        // Sensors & Safety
        case "magsafe_test": Diag_MagSafeTestView()
        case "crash_detection": Diag_CrashDetectionView()
        case "gps_accuracy": Diag_GPSAccuracyView()
        // Safety & Features
        case "emergency_sos": Diag_EmergencySOSView()
        // Haptics
        case "haptic_intensity": Diag_HapticIntensityView()
        // Power
        case "power_delivery": Diag_PowerDeliveryView()
        case "usbc_port": Diag_USBCPortView()
        // Biometrics
        case "face_id_test": Diag_FaceIDTestView()
        case "touch_id_test": Diag_TouchIDTestView()
        // Microphone
        case "microphone_array": Diag_MicrophoneArrayView()
        // Deeper Diagnostics
        case "privacy_report": Diag_PrivacyReportView()
        case "metal_capability": Diag_MetalCapabilityView()
        case "cpu_topology": Diag_CPUTopologyView()
        case "disk_leak": Diag_DiskSpaceLeakView()
        case "bt_packet": Diag_BluetoothPacketView()
        case "adv_traceroute": Diag_NetworkTraceRouteView()
        case "memory_map": Diag_MemoryMapView()
        case "sensor_drift": Diag_SensorDriftView()
        case "white_point": Diag_DisplayWhitePointView()
        case "audio_phase": Diag_AudioPhaseView()
        default:
            Text("Tool not found")
        }
    }
}

struct DiagnosticsCategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
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
            .background(isSelected ? Color.primary : Color(.tertiarySystemFill))
            .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
            .clipShape(Capsule())
        }
    }
}

private struct DiagnosticsHomeSettingsView: View {
    var body: some View {
        DiagnosticsSettingsView()
    }
}

