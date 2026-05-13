
import SwiftUI

struct PluginAssetManagerView: View {
    @Binding var assets: [String]

    var body: some View {
        List {
            Section("Bundle Assets") {
                if assets.isEmpty {
                    ContentUnavailableView("No Assets", systemImage: "folder.badge.plus")
                } else {
                    ForEach(assets, id: \.self) { asset in
                        Text(asset)
                    }
                    .onDelete { assets.remove(atOffsets: $0) }
                }
            }
            Button("Add Asset") { assets.append("asset_\(UUID().uuidString.prefix(4)).png") }
        }
        .navigationTitle("Asset Manager")
    }
}

struct PluginStorageConfigView: View {
    @Binding var quotaMB: Int

    var body: some View {
        Form {
            Stepper("Quota: \(quotaMB) MB", value: $quotaMB, in: 1...500)
            Text("Defines the persistent storage limit for this plugin.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .navigationTitle("Storage")
    }
}

struct PluginLocalizationView: View {
    @Binding var locales: [String]

    var body: some View {
        List {
            ForEach(locales, id: \.self) { locale in
                Text(locale)
            }
            .onDelete { locales.remove(atOffsets: $0) }

            Menu("Add Locale") {
                Button("French (FR)") { locales.append("fr-FR") }
                Button("German (DE)") { locales.append("de-DE") }
                Button("Spanish (ES)") { locales.append("es-ES") }
                Button("Japanese (JP)") { locales.append("ja-JP") }
            }
        }
        .navigationTitle("Localization")
    }
}

struct PluginAnalyticsConfigView: View {
    @Binding var isEnabled: Bool

    var body: some View {
        Form {
            Toggle("Enable Performance Analytics", isOn: $isEnabled)
            Text("When enabled, the SDK will collect execution time and memory usage data for this plugin.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .navigationTitle("Analytics")
    }
}

struct PluginPermissionEscalationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.arrow.up.fill").font(.largeTitle).foregroundStyle(.orange)
            Text("No Active Escalations").font(.headline)
            Text("Plugins can request temporary elevation for restricted scopes.").font(.subheadline).foregroundStyle(.secondary)
        }
        .navigationTitle("Escalation")
    }
}

struct PluginBackgroundTaskView: View {
    @Binding var isEnabled: Bool
    var body: some View {
        Form {
            Toggle("Allow Background Execution", isOn: $isEnabled)
            Text("Allows the plugin to run even when the workspace is in the background.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .navigationTitle("Background")
    }
}

struct PluginSandboxConfigView: View {
    @Binding var level: String
    var body: some View {
        Form {
            Picker("Sandbox Level", selection: $level) {
                Text("Strict (Standard)").tag("Strict")
                Text("Relaxed (Developer)").tag("Relaxed")
                Text("None (Internal Only)").tag("None")
            }
            .pickerStyle(.inline)
        }.navigationTitle("Sandbox")
    }
}

struct PluginPerformanceConfigView: View {
    @Binding var priority: String
    var body: some View {
        Form {
            Picker("Execution Priority", selection: $priority) {
                Text("Low").tag("Low")
                Text("Normal").tag("Normal")
                Text("High").tag("High")
            }
            .pickerStyle(.segmented)
        }
        .navigationTitle("Performance")
    }
}

struct PluginThemeConfigView: View {
    @Binding var accentColor: String
    var body: some View {
        Form {
            TextField("Accent Color Hex", text: $accentColor)
                .font(.system(.body, design: .monospaced))

            ColorPicker("Preview Color", selection: Binding(
                get: { Color(hex: accentColor) ?? .blue },
                set: { accentColor = $0.toHex() ?? accentColor }
            ))
        }
        .navigationTitle("Theme")
    }
}

struct PluginVersionRollbackView: View {
    var body: some View {
        List {
            Section("History") {
                Text("v1.0.0 - Initial Release").font(.subheadline)
            }
        }
        .navigationTitle("Rollback")
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        self.init(red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                  green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                  blue: Double(rgb & 0x0000FF) / 255.0)
    }

    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
