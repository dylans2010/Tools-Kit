import SwiftUI

public struct DiagnosticsSettingsView: View {
    public init() {}
    @Environment(\.dismiss) private var dismiss
    @StateObject private var diagnosticsMode = DiagnosticsModeManager.shared
    @StateObject private var settingsManager = AIChatSettingsManager.shared

    @AppStorage("diagnostics_autoSaveReports") private var autoSaveReports = true
    @AppStorage("diagnostics_showAdvancedTools") private var showAdvancedTools = false
    @AppStorage("diagnostics_enableRepairShopMode") private var enableRepairShopMode = false
    @AppStorage("diagnostics_defaultCategory") private var defaultCategory = "All"
    @AppStorage("diagnostics_hapticFeedback") private var hapticFeedback = true
    @AppStorage("diagnostics_continuousMonitoring") private var continuousMonitoring = false
    @AppStorage("diagnostics_monitoringInterval") private var monitoringInterval: Double = 5.0
    @AppStorage("diagnostics_showToolDescriptions") private var showToolDescriptions = true
    @AppStorage("diagnostics_compactLayout") private var compactLayout = false
    @AppStorage("diagnostics_exportFormat") private var exportFormat = "PDF"
    @AppStorage("diagnostics_autoRunOnLaunch") private var autoRunOnLaunch = false
    @AppStorage("diagnostics_notifyOnCritical") private var notifyOnCritical = true
    @AppStorage("diagnostics_retainHistory") private var retainHistory = true
    @AppStorage("diagnostics_historyDays") private var historyDays: Double = 30
    @AppStorage("diagnostics_networkToolsEnabled") private var networkToolsEnabled = true
    @AppStorage("diagnostics_sensorPollingRate") private var sensorPollingRate: Double = 50
    @AppStorage("diagnostics_batteryAlertThreshold") private var batteryAlertThreshold: Double = 20
    @AppStorage("diagnostics_thermalAlertEnabled") private var thermalAlertEnabled = true
    @AppStorage("diagnostics_showPassFail") private var showPassFail = true

    // New Settings
    @AppStorage("diagnostics_soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("diagnostics_diagnosticDetailLevel") private var detailLevel = "Standard"
    @AppStorage("diagnostics_technicianName") private var technicianName = ""
    @AppStorage("diagnostics_customerName") private var customerName = ""
    @AppStorage("diagnostics_shopName") private var shopName = ""
    @AppStorage("diagnostics_autoExportOnCompletion") private var autoExport = false
    @AppStorage("diagnostics_logLevel") private var logLevel = "Info"
    @AppStorage("diagnostics_theme") private var theme = "System"
    @AppStorage("diagnostics_stressTestDuration") private var stressDuration: Double = 30
    @AppStorage("diagnostics_includeHardwareSerials") private var includeSerials = false
    @AppStorage("diagnostics_enableAIAssist") private var enableAIAssist = true

    @State private var showAppSettings = false
    @State private var showResetConfirmation = false

    private let exportFormats = ["PDF", "JSON", "CSV", "Plain Text"]
    private let categories = ["All"] + DiagnosticCategory.allCases.map(\.rawValue)
    private let detailLevels = ["Basic", "Standard", "Deep", "Technician"]
    private let logLevels = ["Error", "Warning", "Info", "Debug", "Verbose"]
    private let themes = ["System", "Light", "Dark", "High Contrast"]

    public var body: some View {
        NavigationStack {
            Form {
                generalSection
                displaySection
                monitoringSection
                reportsSection
                toolCategoriesSection
                alertsSection
                advancedSection
                appSettingsSection
                resetSection
            }
            .navigationTitle("Diagnostics Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showAppSettings) {
                AIChatSettingsView(settings: $settingsManager.settings)
            }
            .alert("Reset Settings", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetAllSettings() }
            } message: {
                Text("This will restore all Diagnostics settings to their defaults. This action cannot be undone.")
            }
        }
    }

    // MARK: - General

    private var generalSection: some View {
        Section {
            Toggle(isOn: $diagnosticsMode.isDiagnosticsModeEnabled) {
                Label("Diagnostics Mode", systemImage: "stethoscope")
            }
            Toggle(isOn: $hapticFeedback) {
                Label("Haptic Feedback", systemImage: "hand.tap.fill")
            }
            Toggle(isOn: $autoRunOnLaunch) {
                Label("Auto-Run on Launch", systemImage: "play.circle.fill")
            }
            Picker(selection: $defaultCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            } label: {
                Label("Default Category", systemImage: "square.grid.2x2")
            }
        } header: {
            Label("General", systemImage: "gearshape.fill")
        } footer: {
            Text("Controls core behavior of the Diagnostics feature.")
        }
    }

    // MARK: - Display

    private var displaySection: some View {
        Section {
            Toggle(isOn: $showToolDescriptions) {
                Label("Show Tool Descriptions", systemImage: "text.below.photo")
            }
            Toggle(isOn: $compactLayout) {
                Label("Compact Layout", systemImage: "rectangle.compress.vertical")
            }
            Toggle(isOn: $showPassFail) {
                Label("Show Pass/Fail Indicators", systemImage: "checkmark.circle")
            }
        } header: {
            Label("Display", systemImage: "rectangle.on.rectangle")
        }
    }

    // MARK: - Monitoring

    private var monitoringSection: some View {
        Section {
            Toggle(isOn: $continuousMonitoring) {
                Label("Continuous Monitoring", systemImage: "waveform.path.ecg")
            }
            if continuousMonitoring {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Polling Interval: \(String(format: "%.0f", monitoringInterval))s", systemImage: "clock.fill")
                        .font(.subheadline)
                    Slider(value: $monitoringInterval, in: 1...60, step: 1)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Label("Sensor Polling Rate: \(String(format: "%.0f", sensorPollingRate)) Hz", systemImage: "sensor.fill")
                        .font(.subheadline)
                    Slider(value: $sensorPollingRate, in: 10...100, step: 5)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Label("Stress Test Duration: \(String(format: "%.0f", stressDuration))s", systemImage: "timer")
                    .font(.subheadline)
                Slider(value: $stressDuration, in: 10...300, step: 10)
            }
            Picker("Diagnostic Detail", selection: $detailLevel) {
                ForEach(detailLevels, id: \.self) { level in
                    Text(level).tag(level)
                }
            }
        } header: {
            Label("Monitoring & Testing", systemImage: "gauge.with.dots.needle.67percent")
        }
    }

    // MARK: - Reports

    private var reportsSection: some View {
        Section {
            Toggle(isOn: $autoSaveReports) {
                Label("Auto-Save Reports", systemImage: "doc.badge.arrow.up")
            }
            Picker(selection: $exportFormat) {
                ForEach(exportFormats, id: \.self) { format in
                    Text(format).tag(format)
                }
            } label: {
                Label("Export Format", systemImage: "square.and.arrow.up")
            }
            Toggle(isOn: $retainHistory) {
                Label("Retain Report History", systemImage: "clock.arrow.circlepath")
            }
            if retainHistory {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Retention: \(String(format: "%.0f", historyDays)) days", systemImage: "calendar")
                        .font(.subheadline)
                    Slider(value: $historyDays, in: 7...365, step: 1)
                }
            }
        } header: {
            Label("Reports & Export", systemImage: "doc.text.fill")
        }
    }

    // MARK: - Tool Categories

    private var toolCategoriesSection: some View {
        Section {
            Toggle(isOn: $showAdvancedTools) {
                Label("Show Advanced Tools", systemImage: "wrench.and.screwdriver.fill")
            }
            Toggle(isOn: $enableRepairShopMode) {
                Label("Repair Shop Mode", systemImage: "hammer.fill")
            }
            if enableRepairShopMode {
                TextField("Technician Name", text: $technicianName)
                TextField("Customer Name", text: $customerName)
                TextField("Shop / Branch Name", text: $shopName)
                Toggle(isOn: $includeSerials) {
                    Label("Include Serial Numbers", systemImage: "number.square")
                }
            }
            Toggle(isOn: $networkToolsEnabled) {
                Label("Network Tools", systemImage: "network")
            }
            Toggle(isOn: $enableAIAssist) {
                Label("AI Support Assist", systemImage: "sparkles")
            }
        } header: {
            Label("Tool Categories", systemImage: "folder.fill")
        } footer: {
            Text(enableRepairShopMode ? "Repair Shop Mode is active. Reports will include technician and customer metadata." : "Repair Shop Mode enables IMEI lookups, device grading, and pre-repair checklists.")
        }
    }

    // MARK: - Alerts

    private var alertsSection: some View {
        Section {
            Toggle(isOn: $notifyOnCritical) {
                Label("Critical Issue Alerts", systemImage: "exclamationmark.triangle.fill")
            }
            Toggle(isOn: $thermalAlertEnabled) {
                Label("Thermal Alerts", systemImage: "thermometer.high")
            }
            VStack(alignment: .leading, spacing: 4) {
                Label("Battery Alert: \(String(format: "%.0f", batteryAlertThreshold))%", systemImage: "battery.25")
                    .font(.subheadline)
                Slider(value: $batteryAlertThreshold, in: 5...50, step: 5)
            }
        } header: {
            Label("Alerts & Notifications", systemImage: "bell.fill")
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        Section {
            NavigationLink {
                DiagnosticReportsView()
            } label: {
                Label("View All Reports", systemImage: "doc.text.magnifyingglass")
            }

            NavigationLink {
                DiagnosticChatHistory { _ in }
            } label: {
                Label("Diagnostic Chat History", systemImage: "clock.arrow.circlepath")
            }
        } header: {
            Label("Advanced & Data", systemImage: "slider.horizontal.below.square.and.square.filled")
        }
    }

    // MARK: - App Settings

    private var appSettingsSection: some View {
        Section {
            Button {
                showAppSettings = true
            } label: {
                HStack {
                    Label("App Settings", systemImage: "gear")
                    Spacer()
                    Image(systemName: "arrow.up.forward.square")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Application", systemImage: "app.badge.fill")
        } footer: {
            Text("Open the main application settings including AI provider configuration, model settings, and more.")
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Section {
            Picker("Theme", selection: $theme) {
                ForEach(themes, id: \.self) { t in
                    Text(t).tag(t)
                }
            }
            Picker("Log Level", selection: $logLevel) {
                ForEach(logLevels, id: \.self) { l in
                    Text(l).tag(l)
                }
            }
            Toggle(isOn: $soundEffectsEnabled) {
                Label("Sound Effects", systemImage: "speaker.wave.2")
            }
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Reset All Diagnostics Settings", systemImage: "arrow.counterclockwise")
            }
        }
    }

    // MARK: - Helpers

    private func resetAllSettings() {
        autoSaveReports = true
        showAdvancedTools = false
        enableRepairShopMode = false
        defaultCategory = "All"
        hapticFeedback = true
        continuousMonitoring = false
        monitoringInterval = 5.0
        showToolDescriptions = true
        compactLayout = false
        exportFormat = "PDF"
        autoRunOnLaunch = false
        notifyOnCritical = true
        retainHistory = true
        historyDays = 30
        networkToolsEnabled = true
        sensorPollingRate = 50
        batteryAlertThreshold = 20
        thermalAlertEnabled = true
        showPassFail = true
        soundEffectsEnabled = true
        detailLevel = "Standard"
        technicianName = ""
        customerName = ""
        shopName = ""
        autoExport = false
        logLevel = "Info"
        theme = "System"
        stressDuration = 30
        includeSerials = false
        enableAIAssist = true
    }
}
