import SwiftUI

struct DiagnosticsHomeView: View {
    @StateObject private var viewModel = DiagnosticsViewModel()
    @StateObject private var diagnosticsMode = DiagnosticsModeManager.shared
    @State private var showSettings = false
    @State private var showReports = false

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
                        Button {
                            showReports = true
                        } label: {
                            Image(systemName: "doc.text")
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                AIChatSettingsView(settings: .constant(AIChatSettings()))
            }
            .sheet(isPresented: $showReports) {
                NavigationStack {
                    DiagnosticReportsView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Done") { showReports = false }
                            }
                        }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.totalToolCount) Tools")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    if let category = viewModel.selectedCategory {
                        Text(category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                NavigationLink {
                    DiagnosticReportsView()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.caption)
                        Text("Reports")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 4)
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
                        HStack(spacing: 12) {
                            Image(systemName: tool.icon)
                                .font(.body)
                                .foregroundStyle(tool.category.tint)
                                .frame(width: 28, height: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tool.name)
                                    .font(.subheadline.weight(.medium))
                                Text(tool.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 2)
                    }
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
