import SwiftUI

struct PluginSettingsView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @State private var autoUpdateEnabled = true
    @State private var sandboxMode = true
    @State private var maxConcurrent = 5
    @State private var logLevel: PluginLogLevel = .info
    @State private var showConfirmReset = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Auto-update Plugins", isOn: $autoUpdateEnabled)
                Toggle("Sandbox Mode", isOn: $sandboxMode)
                Stepper("Max Concurrent: \(maxConcurrent)", value: $maxConcurrent, in: 1...20)
            }

            Section("Logging") {
                Picker("Log Level", selection: $logLevel) {
                    ForEach(PluginLogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                }
            }

            Section("Permissions") {
                NavigationLink(destination: PluginSecurityView()) {
                    Label("Security Settings", systemImage: "lock.shield")
                }
                LabeledContent("Installed Plugins", value: "\(manager.installedPlugins.count)")
                LabeledContent("Enabled Plugins", value: "\(manager.installedPlugins.filter(\.isEnabled).count)")
            }

            Section("Data") {
                Button("Clear Plugin Cache") {
                    manager.clearCache()
                }
                Button("Reset All Plugin Settings", role: .destructive) {
                    showConfirmReset = true
                }
            }

            Section("About") {
                LabeledContent("Plugin Engine Version", value: "2.0.0")
                LabeledContent("Sandbox Version", value: "1.5.0")
            }
        }
        .navigationTitle("Plugin Settings")
        .alert("Reset Settings?", isPresented: $showConfirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text("This will reset all plugin settings to defaults. Installed plugins will not be removed.")
        }
    }

    private func resetAllSettings() {
        autoUpdateEnabled = true
        sandboxMode = true
        maxConcurrent = 5
        logLevel = .info
    }
}

private enum PluginLogLevel: String, CaseIterable {
    case verbose, debug, info, warning, error
}
